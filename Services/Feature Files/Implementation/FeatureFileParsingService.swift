//
//  FeatureFileParsingService.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

class FeatureFileParsingService: ParsingService {
    
    typealias T = ParsedFeature
    
    func parse(_ data: Data?) -> Result<T, ParsingError> {
        guard let featureFileData = data, !featureFileData.isEmpty,
            let featureFileContent = String(data: featureFileData, encoding: .utf8) else {
            return .failure(.emptyPayload)
        }
        let parsingResult = feature(from: featureFileContent)
        return parsingResult
    }
    
    private func feature(from featureFileText: String) -> Result<T, ParsingError> {
        if let featureDefinition = featureDefinition(from: featureFileText),
            let scenarios = parsedScenarios(from: featureFileText) {
            let name = featureName(from: featureDefinition) ?? "Unnamed"
            let featureTags = tags(from: featureDefinition)
            let text = featureText(from: featureDefinition)
            let tagExpression = self.tagExpression(from: featureDefinition)
            let feature = ParsedFeature(name: name, tags: featureTags, scenarios: scenarios, tagExpression: tagExpression, text: text)
            return .success(feature)
        }
        return .failure(.unexpectedFormat(nil))
    }
    
    func scenarios(from scenariosText: String) -> Result<[ParsedScenario], ParsingError> {
        if let result = parsedScenarios(from: scenariosText) {
            return .success(result)
        }
        return .failure(.unexpectedFormat(nil))
    }
    
    private func parsedScenarios(from featureFileContent: String) -> [ParsedScenario]? {
        if let texts = scenarioTexts(from: featureFileContent) {
            let scenarios: [ParsedScenario] = texts.compactMap { scenarioText in
                guard let name = self.scenarioName(from: scenarioText),
                    let text = self.stepDefinitions(from: scenarioText) else {
                    return nil
                }
                let type = self.scenarioType(from: scenarioText)
                let scenarioTags = self.tags(from: scenarioText)
                let tagExpression = self.tagExpression(from: scenarioText)
                return ParsedScenario(name: name, tagExpression: tagExpression, tags: scenarioTags, text: text, type: type)
            }
            return scenarios
        }
        return nil
    }
    
    private func scenarioType(from scenarioText: String) -> ParsedScenarioType {
        for type in ParsedScenarioType.allCases {
            if scenarioText.lowercased().contains("\(type.rawValue.lowercased()):") {
                return type
            }
        }
        return .scenario
    }

    private func stepDefinitions(from scenarioText: String) -> String? {
        let regEx = "Given(.|\n)+?(\n\n|$)"
        guard let featureNameRegEx = try? NSRegularExpression(pattern: regEx, options: [.caseInsensitive]) else {
            return nil
        }
        let featureContentRange = NSRange(location: 0, length: scenarioText.count)
        let matches = featureNameRegEx.matches(in: scenarioText, options: [], range: featureContentRange)
        let featureFileObjCContent = scenarioText as NSString
        guard let match = matches.first else {
            return nil
        }
        let name = featureFileObjCContent.substring(with: match.range) as String
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func scenarioTexts(from featureFileContent: String) -> [String]? {
        let regEx = "((@.+?)+\n)?\\s*?Scenario:(.|\n)+?(\n\n|$)"
        guard let scenarioRegEx = try? NSRegularExpression(pattern: regEx, options: [.caseInsensitive]) else {
            return nil
        }
        let featureContentRange = NSRange(location: 0, length: featureFileContent.count)
        let matches = scenarioRegEx.matches(in: featureFileContent, options: [], range: featureContentRange)
        let featureFileObjCContent = featureFileContent as NSString
        var scenarios: [String] = []
        for match in matches {
            let scenario = featureFileObjCContent.substring(with: match.range)
            let trimmedScenario = scenario.trimmingCharacters(in: .whitespacesAndNewlines)
            scenarios.append(trimmedScenario)
        }
        return !scenarios.isEmpty ? scenarios : nil
    }
    
    private func scenarioName(from scenarioText: String) -> String? {
        let regEx = "Scenario:(.|\n)+?\n"
        guard let featureNameRegEx = try? NSRegularExpression(pattern: regEx, options: [.caseInsensitive]) else {
            return nil
        }
        let featureContentRange = NSRange(location: 0, length: scenarioText.count)
        let matches = featureNameRegEx.matches(in: scenarioText, options: [], range: featureContentRange)
        let featureFileObjCContent = scenarioText as NSString
        guard let match = matches.first else {
            return nil
        }
        let matchingString = featureFileObjCContent.substring(with: match.range) as String
        // Remove the 'scenario:' prefix
        let startIdx = matchingString.index(matchingString.startIndex, offsetBy: 9)
        let endIdx = matchingString.endIndex
        let name = String(matchingString[startIdx..<endIdx])
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Uses regex to extract the feature definition from the content of the feature file.
    /// - parameter featureFileContent: The content of a feature file represented as a `String`.
    /// - returns: The feature defintiion or nil if the definition could not be extracted.
    func featureDefinition(from featureFileContent: String) -> String? {
        let extractionRegEx = "((@.+?)+\n)?Feature:.+?\n(.+\n)?"
        guard let featureRegEx = try? NSRegularExpression(pattern: extractionRegEx, options: [.caseInsensitive]) else {
            return nil
        }
        let featureContentRange = NSRange(location: 0, length: featureFileContent.count)
        let matches = featureRegEx.matches(in: featureFileContent, options: [], range: featureContentRange)
        let featureFileObjCContent = featureFileContent as NSString
        guard let match = matches.first else {
            return nil
        }
        return featureFileObjCContent.substring(with: match.range)
    }
    
    func featureText(from featureText: String) -> String? {
        let regEx = "Feature:(.|\n)+?$"
        guard let featureNameRegEx = try? NSRegularExpression(pattern: regEx, options: [.caseInsensitive]) else {
            return nil
        }
        let featureContentRange = NSRange(location: 0, length: featureText.count)
        let matches = featureNameRegEx.matches(in: featureText, options: [], range: featureContentRange)
        let featureFileObjCContent = featureText as NSString
        guard let match = matches.first else {
            return nil
        }
        let matchingString = featureFileObjCContent.substring(with: match.range) as String
        let components = matchingString.split(separator: "\n")
        guard components.count >= 2 else {
            return nil
        }
        return String(components[1])
    }
    
    func featureName(from featureFileContent: String) -> String? {
        let regEx = "Feature:(.|\n)+?\n"
        guard let featureNameRegEx = try? NSRegularExpression(pattern: regEx, options: [.caseInsensitive]) else {
            return nil
        }
        let featureContentRange = NSRange(location: 0, length: featureFileContent.count)
        let matches = featureNameRegEx.matches(in: featureFileContent, options: [], range: featureContentRange)
        let featureFileObjCContent = featureFileContent as NSString
        guard let match = matches.first else {
            return nil
        }
        let matchingString = featureFileObjCContent.substring(with: match.range) as String
        // Remove the 'feature:' prefix
        let startIdx = matchingString.index(matchingString.startIndex, offsetBy: 8)
        let endIdx = matchingString.endIndex
        let name = String(matchingString[startIdx..<endIdx])
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func tagExpression(from string: String) -> String? {
        let regEx = "@.+\n"
        guard let tagExpressionRegEx = try? NSRegularExpression(pattern: regEx, options: [.caseInsensitive]) else {
            return nil
        }
        let tagExpressionRange = NSRange(location: 0, length: string.count)
        let matches = tagExpressionRegEx.matches(in: string, options: [], range: tagExpressionRange)
        let stringObjCContent = string as NSString
        guard let match = matches.first else {
            return nil
        }
        let matchingString = stringObjCContent.substring(with: match.range) as String
        return matchingString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Uses regex to extract tags from a given string.
    /// - parameter string: The `String` from which to extract tags.
    /// - returns: An array of tags extracted from the provided string or nil if tags could not be extracted.
    func tags(from string: String) -> [String]? {
        guard let tagsRegEx = try? NSRegularExpression(pattern: "@[a-zA-Z0-9]+", options: [.caseInsensitive]) else {
            return nil
        }
        var tags: [String] = []
        let tagExpressionRange = NSRange(location: 0, length: string.count)
        let matches = tagsRegEx.matches(in: string, options: [], range: tagExpressionRange)
        let tagExpressionObjCContent = string as NSString
        for match in matches {
            let tag = tagExpressionObjCContent.substring(with: match.range)
            let tagWithoutAt = String(tag[tag.startIndex..<tag.endIndex])
            tags.append(tagWithoutAt)
        }
        return !tags.isEmpty ? tags : nil
    }
    
}
