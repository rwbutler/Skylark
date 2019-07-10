//
//  ScenarioReport.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

enum ScenarioReport {
    case scenario(_ scenario: Scenario, result: ScenarioResult)
    case scenarioOutline(_ scenario: Scenario, results: [ScenarioOutlineResult])
    case scenarioPermutations(_ scenario: Scenario, results: [ScenarioOutlineResult])
}

extension ScenarioReport: CustomStringConvertible {
    
    var boolValue: Bool {
        let overallResult = TestReporter(scenarioReports: [self], output: Skylark.outputs)
        return overallResult.boolValue
    }
    
    var description: String {
        let scenario: Scenario
        switch self {
        case .scenario(let parsedScenario, _):
            scenario = parsedScenario
        case .scenarioOutline(let parsedScenario, _),
             .scenarioPermutations(let parsedScenario, results: _):
            scenario = parsedScenario
        }
        var reportText: String = "\nTest report for scenario '\(scenario.name)':\n\n"
        let overallResult = TestReporter(scenarioReports: [self], output: Skylark.outputs)
        reportText += overallResult.summary()
        return reportText
    }
}
