//
//  ScenarioTagsService.swift
//  Skylark
//
//  Created by Ross Butler on 9/26/18.
//

import Foundation

/// Compiles a tag expression into an evaluable to determine whether or not scenarios should be executed.
/// For information on tag expressions see: https://docs.cucumber.io/cucumber/tag-expressions/
struct ScenarioTagsService {

    /// Expression which determines which tagged scenarios should be executed
    private let tagExpression: String

    /// Instantiated only once
    init?(tagExpression: String) {
        self.tagExpression = tagExpression
        let tagsInExpression = tags(inExpression: tagExpression)
        guard complexEvaluable(from: tagExpression, scenarioTags: tagsInExpression) != nil else {
            return nil
        }
    }

    /// Evaluates whether the supplied scenario should be executed given the tag expression.
    func shouldExecuteScenario(_ scenario: String) -> Bool {
        let scenarioTags = tags(appliedToScenario: scenario)
        return shouldExecuteScenario(tagExpression: tagExpression, scenarioTags: scenarioTags)
    }

}

// Private API
private extension ScenarioTagsService {

    /// Compiles a complex expression (containing multiple conjunctions) into an evaluable.
    func complexEvaluable(from expression: String, scenarioTags: [String]) -> Step? {

        // Match against regular expression
        let expressionRange = NSRange(location: 0, length: expression.count)
        // swiftlint:disable:next force_try
        let parenthenisedExpressionRegEx = try! NSRegularExpression(pattern: "\\([@a-z0-9\\s]+?\\)",
                                                                   options: [.caseInsensitive])
        let matches = parenthenisedExpressionRegEx.matches(in: expression, options: [], range: expressionRange)

        // Construct array of consitituent expressions
        var constituentExpressions: [String] = []
        var startIndex: Int = 0
        for match in matches {
            let endIndex = match.range.lowerBound
            let substringRange = NSRange(location: startIndex, length: endIndex - startIndex)
            let conjunction = (expression as NSString).substring(with: substringRange)
            constituentExpressions.append(conjunction)
            let expressionRange = NSRange(location: match.range.lowerBound + 1, length: match.range.length - 2)
            let parenthesisedExpression = (expression as NSString).substring(with: expressionRange)
            constituentExpressions.append(parenthesisedExpression)
            startIndex = match.range.upperBound
        }
        let conjunctionRange = NSRange(location: startIndex, length: expression.count - startIndex)
        let conjunction = (expression as NSString).substring(with: conjunctionRange)
        constituentExpressions.append(conjunction)

        // Trim whitespace from expressions and remove empty Strings
        constituentExpressions = constituentExpressions.compactMap({
            let trimmedExpression = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedExpression != "" else { return nil }
            return trimmedExpression
        })

        var expressionStack: [Step] = []
        var currentOperator: Operator?
        for expression in constituentExpressions {
            guard let operation = Operator(rawValue: expression) else {
                if var currentExpression = compoundEvaluable(expression: expression, tags: scenarioTags) {
                    if let conjunction = currentOperator, let poppedExpression = expressionStack.popLast() {
                        switch conjunction {
                        case .and:
                            currentExpression = AndStep(lhs: poppedExpression, rhs: currentExpression)
                            currentOperator = nil
                        case .or:
                            currentExpression = OrStep(lhs: poppedExpression, rhs: currentExpression)
                            currentOperator = nil
                        }
                    }
                    expressionStack.append(currentExpression)
                }
                continue // Warning: Unable to evaluate the expression - consider returning nil here.
            }
            currentOperator = operation
        }
        return expressionStack.popLast()
    }

    /// Compiles a compound expression (with at most one conjunction) into an evaluable.
    private func compoundEvaluable(expression: String, tags: [String]) -> Step? {
        if let simpleEvaluable = simpleEvaluable(expression: expression, tags: tags) {
            return simpleEvaluable
        }
        var components = expression.components(separatedBy: " and ")
        if  components.count == 2,
            let lhs = compoundEvaluable(expression: components[0], tags: tags),
            let rhs = compoundEvaluable(expression: components[1], tags: tags) {
            return AndStep(lhs: lhs, rhs: rhs)
        }
        components = expression.components(separatedBy: " but ") // allows us to write 'but not'
        if  components.count == 2,
            let lhs = compoundEvaluable(expression: components[0], tags: tags),
            let rhs = compoundEvaluable(expression: components[1], tags: tags) {
            return AndStep(lhs: lhs, rhs: rhs)
        }
        components = expression.components(separatedBy: " or ")
        if  components.count == 2,
            let lhs = compoundEvaluable(expression: components[0], tags: tags),
            let rhs = compoundEvaluable(expression: components[1], tags: tags) {
            return OrStep(lhs: lhs, rhs: rhs)
        }
        return nil
    }

    /// Evaluates whether the supplied String is a scenario tag.
    private func isTag(_ potentialTag: String) -> Bool {
        // swiftlint:disable:next force_try
        let tagRegularExpression = try! NSRegularExpression(pattern: "^@[a-z0-9]+?$", options: [.caseInsensitive])
        let potentialTagRange = NSRange(location: 0, length: potentialTag.count)
        return tagRegularExpression.firstMatch(in: potentialTag, options: [], range: potentialTagRange) != nil
    }

    /// Decides whether or not a scenario with the specified tags should execute given the
    private func shouldExecuteScenario(tagExpression: String, scenarioTags: [String]) -> Bool {
        if let condition = complexEvaluable(from: tagExpression, scenarioTags: scenarioTags) {
            return condition.evaluate()
        }
        // Warning: Unable to parse the expression (should have guarded against this with conditional intializer).
        return false
    }

    /// Compiles a simple expression (without any conjunctions) into an evaluable.
    private func simpleEvaluable(expression: String, tags: [String]) -> Step? {
        if isTag(expression) {
            return SimpleStep({ tags.contains(expression) })
        }
        let prefix = "not "
        if expression.hasPrefix(prefix) {
            if let expression = compoundEvaluable(expression: String(expression.dropFirst(prefix.count)), tags: tags) {
                return NegatedStep(expr: expression)
            }
        }
        return nil
    }

    /// Identifies all tags in the given tag expression.
    func tags(inExpression tagExpression: String) -> [String] {
        var tags: [String] = []
        let tagExpressionRange = NSRange(location: 0, length: tagExpression.count)
        // swiftlint:disable:next force_try
        let tagRegularExpression = try! NSRegularExpression(pattern: "@[a-z0-9]+", options: [.caseInsensitive])
        let matches = tagRegularExpression.matches(in: tagExpression, options: [], range: tagExpressionRange)
        for match in matches {
            let tag = (tagExpression as NSString).substring(with: match.range)
            tags.append(tag)
        }
        return tags
    }

    /// Identifies all of the tags that have been applied to the specified scenario.
    func tags(appliedToScenario scenario: String) -> [String] {
        guard let scenarioTagLine = scenario.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n").first else { return [] }
        return tags(inExpression: scenarioTagLine)
    }
}
