//
//  ScenarioReport.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

enum ScenarioReport {
    case scenario(_ scenario: ParsedScenario, result: ScenarioResult)
    case scenarioOutline(_ scenario: ParsedScenario, results: [ScenarioOutlineResult])
    case scenarioPermutations(_ scenario: ParsedScenario, results: [ScenarioOutlineResult])
}

extension ScenarioReport: CustomStringConvertible {
    
    var boolValue: Bool {
        let overallResult = TestExecutionResultReporter(scenarioReports: [self])
        return overallResult.boolValue
    }
    
    var description: String {
        let scenario: ParsedScenario
        switch self {
        case .scenario(let parsedScenario, _):
            scenario = parsedScenario
        case .scenarioOutline(let parsedScenario, _),
             .scenarioPermutations(let parsedScenario, results: _):
            scenario = parsedScenario
        }
        var reportText: String = "\nTest Report for scenario '\(scenario.name)':\n\n"
        let overallResult = TestExecutionResultReporter(scenarioReports: [self])
        reportText += overallResult.summary()
        return reportText
    }
}
