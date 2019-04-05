//
//  ScenarioExecutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/12/19.
//

import Foundation
import XCTest

class ScenarioExecutionService: ExecutionService {
    
    private let launchArgs: [LaunchArguments]
    private let stepResolver: StepResolutionService
    
    init(stepResolver: StepResolutionService, arguments: [LaunchArguments]) {
        self.launchArgs = arguments
        self.stepResolver = stepResolver
    }
    
    func launchRoutine(launchArguments: [LaunchArguments]) -> () -> Void {
        var args: [String] = []
        for arg in launchArgs {
            if case .custom(let flag) = arg {
                args.append(flag)
            }
        }
        let launch: () -> Void = {
            let application = XCUIApplication()
            if application.state == .runningForeground {
                application.terminate()
            }
            application.launchArguments = args
            application.launch()
        }
        return launch
    }
    
    // Executes a feature
    func execute(feature: ParsedFeature, retryCount: Int = 0) -> FeatureReport {
        /*guard let tagExpression = self.tagExpression(), let featureTags = feature.tagExpression,
         let decisionService = ScenarioTagsService(tagExpression: tagExpression) else {
         let result: FeatureResult = .notExecuted(.unrecognizedTagExpression)
         return FeatureReport(feature: feature, scenarioReports: [], result: result)
         }
         let shouldExecuteFeature = decisionService.shouldExecuteScenario(featureTags)
         guard shouldExecuteFeature else {
         let result: FeatureResult = .notExecuted(.tagMismatch(tagExpr: featureTags, testRunnerTagExpr: tagExpression))
         return FeatureReport(feature: feature, scenarioReports: [], result: result)
         }*/
        let launch = launchRoutine(launchArguments: launchArgs)
        if !launchArgs.contains(where: { $0 == .resetBeforeEachScenario }) {
            launch()
        }
        let scenarioResults: [ScenarioReport] = execute(scenarios: feature.scenarios, additionalTags: feature.tags, retryCount: retryCount)
        let overallResult = featureResult(from: scenarioResults)
        return FeatureReport(feature: feature, scenarioReports: scenarioResults, result: overallResult)
    }
    
    private func featureResult(from scenarioReports: [ScenarioReport]) -> FeatureResult {
        var scenarioFailures: [ScenarioFailure] = []
        for report in scenarioReports {
            switch report {
            case .scenario(_, let result):
                if case .failure(let reason) = result {
                    scenarioFailures.append(reason)
                }
            case .scenarioOutline(_, let results), .scenarioPermutations(_, let results):
                let failureReasons: [ScenarioFailure] = results.compactMap { result in
                    if case .failure(let reason) = result.result {
                        return reason
                    }
                    return nil
                }
                scenarioFailures.append(contentsOf: failureReasons)
            }
        }
        return (scenarioFailures.isEmpty) ? .success : .failure(scenarioFailures)
    }
    
    func execute(scenarios: [ParsedScenario], additionalTags: [ParsedTag]? = nil, retryCount: Int = 0) -> [ScenarioReport] {
        let outlineParser = ScenarioOutlineParser()
        var results: [ScenarioReport] = []
            
        if !launchArgs.contains(where: { $0 == .resetBeforeEachScenario }) {
            launchRoutine(launchArguments: launchArgs)()
        }
        
        for scenario in scenarios {
            
            guard let tagExpression = self.tagExpression(),
                let conditionalExecutionService = ScenarioTagsService(tagExpression: tagExpression) else {
                    let result: ScenarioResult = .notExecuted(.unrecognizedTagExpression)
                    results.append(ScenarioReport.scenario(scenario, result: result))
                    continue
            }
            let scenarioTagExpr = scenario.tagExpression ?? ""
            var scenarioTags = scenario.tags ?? []
            if let additionalTags = additionalTags {
                scenarioTags.append(contentsOf: additionalTags)
            }
            let shouldExecuteFeature = conditionalExecutionService.shouldExecuteScenario(tags: scenarioTags)
            let nonExecutionResult: ScenarioResult = .notExecuted(.tagMismatch(tagExpr: scenarioTagExpr, testRunnerTagExpr: tagExpression))
            
            if !shouldExecuteFeature {
                results.append(ScenarioReport.scenario(scenario, result: nonExecutionResult))
                continue
            }
            
            if launchArgs.contains(where: { $0 == .resetBeforeEachScenario }) {
                launchRoutine(launchArguments: launchArgs)()
            }
            
            Services.contextManagement?.reset()
            
            switch scenario.type {
            case .scenario:
                let result = scenarioReport(name: scenario.name, scenarioText: scenario.text, retryCount: retryCount)
                results.append(ScenarioReport.scenario(scenario, result: result))
            case .scenarioOutline, .scenarioPermutations:
                let scenarioTexts = outlineParser.scenariosWithExampleSubstitutions(scenario: scenario.text, type: scenario.type)
                var outlineResults: [ScenarioOutlineResult] = []
                for scenarioText in scenarioTexts {
                    let result = scenarioReport(name: scenario.name, scenarioText: scenarioText, retryCount: retryCount)
                    outlineResults.append(ScenarioOutlineResult(result: result, scenarioText: scenarioText))
                }
                if case .scenarioOutline = scenario.type {
                    results.append(ScenarioReport.scenarioOutline(scenario, results: outlineResults))
                }
                if case .scenarioPermutations = scenario.type {
                    results.append(ScenarioReport.scenarioPermutations(scenario, results: outlineResults))
                }
            }
        }
        return results
    }
    
    func scenarioReport(name: String, scenarioText: String, retryCount: Int = 0) -> ScenarioResult {
        if launchArgs.contains(where: { $0 == .resetBeforeEachScenario }) {
            launchRoutine(launchArguments: launchArgs)()
        }
        print("Testing scenario...\n\(name)\n\n")
        let result = evaluate(scenario: scenarioText)
        var flakyResults: [ScenarioResult] = []
        if case .failure = result, retryCount > 0 {
            flakyResults.append(result)
            for _ in 0..<retryCount {
                print("Re-testing scenario...\n\(name)\n\n")
                let result = evaluate(scenario: scenarioText)
                flakyResults.append(result)
            }
            // Require 50% success rate currently. In future this ought to be configurable.
            let numberOfAttempts = flakyResults.count
            let numberRequiredSuccesses: Int = Int((Double(numberOfAttempts) / Double(2.0)).rounded(.up))
            let numberOfSuccesses = flakyResults.filter({ $0 == ScenarioResult.success }).count
            if numberRequiredSuccesses <= numberOfSuccesses {
                return .flaky(flakyResults)
            }
        }
        return result
    }
    
    func evaluable(for step: String) -> Evaluable? {
        return stepResolver.resolve(step: step)
    }
    
    func stepIsPrefixedByConjunction(step: String) -> Bool {
        let conjunctions = ["and", "or", "but"]
        for conjunction in conjunctions where step.starts(with: conjunction) {
            return true
        }
        return false
    }
    
    func evaluate(scenario: String) -> ScenarioResult {
        let steps: [String] = scenario.split(separator: "\n").map({ String($0) })
        
        var previousStep: GherkinStep?
        for step in steps {
            let trimmedStep = step.lowercased().trimmingCharacters(in: CharacterSet.whitespaces)
            if let previousEvaluable = previousStep {
                guard previousEvaluable.evaluable.evaluate() else {
                    return .failure(.stepFailure(previousEvaluable.text))
                }
                if let eval = evaluable(for: trimmedStep) {
                    previousStep = GherkinStep(evaluable: eval, text: step)
                } else {
                    return .failure(.noMatchingStep(step))
                }
            }
            if let eval = evaluable(for: trimmedStep) {
                previousStep = GherkinStep(evaluable: eval, text: step)
            } else {
                return .failure(.noMatchingStep(step))
            }
            
            /*
            
            if stepIsPrefixedByConjunction(step: trimmedStep),
                let currentEvaluable = evaluable(for: trimmedStep),
                let previousEvaluable = previousStep {
                if trimmedStep.starts(with: "and") {
                    let andStep = AndStep(lhs: previousEvaluable.evaluable, rhs: currentEvaluable)
                    previousStep = GherkinStep(evaluable: andStep, text: "\(previousEvaluable.text)\n\(step)")
                }
                if trimmedStep.starts(with: "or") {
                    let orStep = OrStep(lhs: previousEvaluable.evaluable, rhs: currentEvaluable)
                    previousStep = GherkinStep(evaluable: orStep, text: "\(previousEvaluable.text)\n\(step)")
                }
                if trimmedStep.starts(with: "but") {
                    let butEvaluable = NegatedStep(expr: currentEvaluable)
                    let butStep = AndStep(lhs: previousEvaluable.evaluable, rhs: butEvaluable)
                    previousStep = GherkinStep(evaluable: butStep, text: "\(previousEvaluable.text)\n\(step)")
                }
            } else if let previousEvaluable = previousStep {
                guard previousEvaluable.evaluable.evaluate() else {
                    return .failure(.stepFailure(previousEvaluable.text))
                }
                if let eval = evaluable(for: trimmedStep) {
                    previousStep = GherkinStep(evaluable: eval, text: step)
                } else {
                    return .failure(.noMatchingStep(step))
                }
            } else if let eval = evaluable(for: trimmedStep) {
                previousStep = GherkinStep(evaluable: eval, text: step)
            } else {
                return .failure(.noMatchingStep(step))
            }
            */
            
        }
        
        
        
        if let previousEvaluable = previousStep {
            guard previousEvaluable.evaluable.evaluate() else {
                return .failure(.stepFailure(previousEvaluable.text))
            }
            return .success
        }
        return .success
    }
    
    /// Evaluates whether the supplied scenario should be executed given the current tag expression.
    func shouldExecuteScenario(tags: [String]) -> Bool {
        guard let tagExpression = tagExpression() else { return true }
        
        // No scenarios will be executed in the tag expression could not be evaluated.
        return ScenarioTagsService(tagExpression: tagExpression)?.shouldExecuteScenario(tags: tags) ?? false
    }
    
    private func tagExpression() -> String? {
        for index in 1..<CommandLine.arguments.count
            where CommandLine.arguments[index] == "--tags" && index + 1 < CommandLine.arguments.count {
                return CommandLine.arguments[index + 1]
        }
        return nil
    }
}
