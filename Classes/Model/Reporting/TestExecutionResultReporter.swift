//
//  TestExecutionResultReporter.swift
//  Skylark
//
//  Created by Ross Butler on 4/3/19.
//

import Foundation
import XCTest

struct TestExecutionResultReporter {
    let numberOfScenariosPassed: Int
    let numberOfScenariosFlaky: Int
    let numberOfScenariosFailed: Int
    let numberOfScenariosNotExecuted: Int

    var boolValue: Bool {
        return numberOfScenariosFailed == 0
    }
    
    var numberOfScenariosExecuted: Int {
        return numberOfScenariosPassed + numberOfScenariosFlaky + numberOfScenariosFailed
    }
    
    var percentageScenariosPassed: Double {
        return (Double(numberOfScenariosPassed) / Double(numberOfScenariosExecuted)) * 100.0
    }
    
    var percentageScenariosFlaky: Double {
        return (Double(numberOfScenariosFlaky) / Double(numberOfScenariosExecuted)) * 100.0
    }
    
    var percentageScenariosFailed: Double {
        return (Double(numberOfScenariosFailed) / Double(numberOfScenariosExecuted)) * 100.0
    }
    
    var totalNumberOfScenarios: Int {
        return numberOfScenariosExecuted + numberOfScenariosNotExecuted
    }
    
    init(scenarioResults: [ScenarioResult]) {
        var numberScenariosPassed = 0
        var numberScenariosFlaky = 0
        var numberScenariosFailed = 0
        var notExecutedCount = 0
        for result in scenarioResults {
            switch result {
            case .success:
                numberScenariosPassed += 1
            case .flaky:
                numberScenariosFlaky += 1
            case .failure:
                numberScenariosFailed += 1
            case .notExecuted:
                notExecutedCount += 1
            }
        }
            self.numberOfScenariosPassed = numberScenariosPassed
            self.numberOfScenariosFlaky = numberScenariosFlaky
            self.numberOfScenariosFailed = numberScenariosFailed
            self.numberOfScenariosNotExecuted = notExecutedCount
        }
    
    init(scenarioOutlineResults: [ScenarioOutlineResult]) {
        let results = scenarioOutlineResults.map { $0.result }
        self.init(scenarioResults: results)
    }
    
    init(scenarioReports: [ScenarioReport]) {
        var scenarioResults: [ScenarioResult] = []
        for scenarioReport in scenarioReports {
            switch scenarioReport {
            case .scenario(let report):
                scenarioResults.append(report.result)
            case .scenarioOutline(_, let results), .scenarioPermutations(_, let results):
                scenarioResults.append(contentsOf: results.map { $0.result })
            }
        }
        self.init(scenarioResults: scenarioResults)
    }
    
    func printSummary() {
        print(summary())
    }
    
    func stringRepresentationScenariosPassed() -> String {
        if totalNumberOfScenarios == 1 {
            return "Passed ✅"
        } else {
            let percentagePassed = stringRepresentationToOneDecimalPlace(percentageScenariosPassed)
            return "\(numberOfScenariosPassed) (\(percentagePassed)%) passed ✅"
        }
    }
    
    func stringRepresentationScenariosFlaky() -> String {
        if totalNumberOfScenarios == 1 {
            return "Flaky ⚠️"
        } else {
            let percentageFlaky = stringRepresentationToOneDecimalPlace(percentageScenariosFlaky)
            return "\(numberOfScenariosFlaky) (\(percentageFlaky)%) flaky ⚠️"
        }
    }

    func stringRepresentationScenariosFailed() -> String {
        if totalNumberOfScenarios == 1 {
            return "Failed ❌"
        } else {
            let percentageFailed = stringRepresentationToOneDecimalPlace(percentageScenariosFailed)
            return "\(numberOfScenariosFailed) (\(percentageFailed)%) failed ❌"
        }
    }
    
    func stringRepresentationScenariosNotExecuted() -> String {
        if totalNumberOfScenarios == 1 {
            return "Not executed 🙅🏻‍♂️"
        } else {
            return "\(numberOfScenariosNotExecuted) not executed 🙅🏻‍♂️"
        }
    }

    func stringRepresentationToOneDecimalPlace(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }
    
    func summary() -> String {
        var summaryText = "\nSummary\n"
        if numberOfScenariosPassed > 0 {
            summaryText += "\t\(stringRepresentationScenariosPassed())\n"
        }
        if numberOfScenariosFlaky > 0 {
            summaryText += "\t\(stringRepresentationScenariosFlaky())\n"
        }
        if numberOfScenariosFailed > 0 {
            summaryText += "\t\(stringRepresentationScenariosFailed())\n"
        }
        if numberOfScenariosNotExecuted > 0 {
            summaryText += "\t\(stringRepresentationScenariosNotExecuted())\n"
        }
        if totalNumberOfScenarios > 1 {
            summaryText += "\n\tTotal: \(totalNumberOfScenarios) scenarios.\n"
        }
        return summaryText
    }
}
