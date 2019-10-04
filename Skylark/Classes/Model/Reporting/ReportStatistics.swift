//
//  ReportStatistics.swift
//  Skylark
//
//  Created by Ross Butler on 9/24/19.
//

import Foundation

struct ReportStatistics {
    
    let numberOfScenariosPassed: Int
    let numberOfScenariosFlaky: Int
    let numberOfScenariosFailed: Int
    let numberOfScenariosNotExecuted: Int
    
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
    
    init(results: [ScenarioResult]) {
        var numberScenariosPassed = 0
        var numberScenariosFlaky = 0
        var numberScenariosFailed = 0
        var notExecutedCount = 0
        for result in results {
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
    
    func stringRepresentationScenariosPassed() -> String {
        let emojiString = Skylark.emojiInOutput ? " ✅" : "."
        if totalNumberOfScenarios <= 1 {
            return "Passed\(emojiString)"
        } else {
            let percentagePassed = TestReporter.stringRepresentationToOneDecimalPlace(percentageScenariosPassed)
            return "\(numberOfScenariosPassed) (\(percentagePassed)%) passed\(emojiString)"
        }
    }
    
    func stringRepresentationScenariosFlaky() -> String {
        let emojiString = Skylark.emojiInOutput ? " ⚠️" : "."
        if totalNumberOfScenarios <= 1 {
            return "Flaky\(emojiString)"
        } else {
            let percentageFlaky = TestReporter.stringRepresentationToOneDecimalPlace(percentageScenariosFlaky)
            return "\(numberOfScenariosFlaky) (\(percentageFlaky)%) flaky\(emojiString)"
        }
    }
    
    func stringRepresentationScenariosFailed() -> String {
        let emojiString = Skylark.emojiInOutput ? " ❌" : "."
        if totalNumberOfScenarios <= 1 {
            return "Failed\(emojiString)"
        } else {
            let percentageFailed = TestReporter.stringRepresentationToOneDecimalPlace(percentageScenariosFailed)
            return "\(numberOfScenariosFailed) (\(percentageFailed)%) failed\(emojiString)"
        }
    }
    
    func stringRepresentationScenariosNotExecuted() -> String {
        let emojiString = Skylark.emojiInOutput ? " 🙅🏻‍♂️" : "."
        if totalNumberOfScenarios <= 1 {
            return "Not executed\(emojiString)"
        } else {
            return "\(numberOfScenariosNotExecuted) not executed\(emojiString)"
        }
    }
    
    func stringRepresentationToOneDecimalPlace(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }
    
}
