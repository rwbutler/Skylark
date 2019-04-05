//
//  FeatureFileReport.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

struct FeatureReport {
    
    let feature: ParsedFeature
    
    var scenarioReports: [ScenarioReport] = []
    
    let result: FeatureResult
}

extension FeatureReport: CustomStringConvertible {
    var description: String {
        var reportText: String = "\nTest Report for feature '\(feature.name)':\n\n"
        for container in scenarioReports {
            switch container {
            case .scenario(let scenario, let result):
                reportText += "Scenario: \(scenario.name) => \(result)\n"
                if case .failure(let cause) = result {
                    reportText += "\tCause -> \(cause)\n"
                }
            case .scenarioOutline(let scenario, let results), .scenarioPermutations(let scenario, let results):
                for result in results {
                    reportText += "Scenario: \(scenario.name) => \(result)\n"
                    /*if case .failure(let cause) = result {
                        reportText += "\tCause -> \(cause)\n"
                    }*/
                }
            }
        }
        let overallResult = TestExecutionResultReporter(scenarioReports: scenarioReports)
        reportText += overallResult.summary()
        return reportText
    }
}
