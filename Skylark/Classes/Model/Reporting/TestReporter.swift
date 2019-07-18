//
//  TestExecutionResultReporter.swift
//  Skylark
//
//  Created by Ross Butler on 4/3/19.
//

import Foundation
import XCTest

struct TestReporter {
    
    // MARK: Type Definitions
    private struct FailureReport {
        let scenario: Scenario
        let failureResults: [ScenarioFailure]
    }
    
    private enum Source {
        case feature
        case scenario
    }
    
    // MARK: - State
    private let numberOfScenariosPassed: Int
    private let numberOfScenariosFlaky: Int
    private let numberOfScenariosFailed: Int
    private let numberOfScenariosNotExecuted: Int
    private let outputs: [Skylark.Output]
    private var scenarioReports: [ScenarioReport]?
    
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
    
    // MARK: - Initializers
    
    init(featureReport: FeatureReport, output: [Skylark.Output]) {
        self.init(scenarioReports: featureReport.scenarioReports, output: output)
    }
    
    init(scenarioReports: [ScenarioReport], output: [Skylark.Output]) {
        var scenarioResults: [ScenarioResult] = []
        for scenarioReport in scenarioReports {
            switch scenarioReport {
            case .scenario(let report):
                scenarioResults.append(report.result)
            case .scenarioOutline(_, let results), .scenarioPermutations(_, let results):
                scenarioResults.append(contentsOf: results.map { $0.result })
            }
        }
        self.init(scenarioResults: scenarioResults, output: output)
        self.scenarioReports = scenarioReports
    }
    
    private init(scenarioResults: [ScenarioResult], output: [Skylark.Output]) {
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
        self.outputs = output
    }
    
    init(_ testReports: [TestReport], output: [Skylark.Output]) {
        var reports: [ScenarioReport] = []
        for testReport in testReports {
            switch testReport {
            case .feature(let featureReport):
                reports.append(contentsOf: featureReport.scenarioReports)
            case .scenarios(let scenarioReports):
                reports.append(contentsOf: scenarioReports)
            }
        }
        self.init(scenarioReports: reports, output: output)
    }
    
    func report() {
        let reportText = summary()
        for channel in outputs {
            switch channel {
            case .debugPrint:
                debugPrint(summary())
            case .print:
                print(summary())
            case .slack(let webHookURL):
                reportUsingSlack(webHookURL: webHookURL, message: reportText)
            }
        }
    }
    
    func stringRepresentationScenariosPassed() -> String {
        let emojiString = Skylark.emojiInOutput ? " ✅" : "."
        if totalNumberOfScenarios == 1 {
            return "Passed\(emojiString)"
        } else {
            let percentagePassed = stringRepresentationToOneDecimalPlace(percentageScenariosPassed)
            return "\(numberOfScenariosPassed) (\(percentagePassed)%) passed\(emojiString)"
        }
    }
    
    func stringRepresentationScenariosFlaky() -> String {
        let emojiString = Skylark.emojiInOutput ? " ⚠️" : "."
        if totalNumberOfScenarios == 1 {
            return "Flaky\(emojiString)"
        } else {
            let percentageFlaky = stringRepresentationToOneDecimalPlace(percentageScenariosFlaky)
            return "\(numberOfScenariosFlaky) (\(percentageFlaky)%) flaky\(emojiString)"
        }
    }
    
    func stringRepresentationScenariosFailed() -> String {
        let emojiString = Skylark.emojiInOutput ? " ❌" : "."
        if totalNumberOfScenarios == 1 {
            return "Failed\(emojiString)"
        } else {
            let percentageFailed = stringRepresentationToOneDecimalPlace(percentageScenariosFailed)
            return "\(numberOfScenariosFailed) (\(percentageFailed)%) failed\(emojiString)"
        }
    }
    
    func stringRepresentationScenariosNotExecuted() -> String {
        let emojiString = Skylark.emojiInOutput ? " 🙅🏻‍♂️" : "."
        if totalNumberOfScenarios == 1 {
            return "Not executed\(emojiString)"
        } else {
            return "\(numberOfScenariosNotExecuted) not executed\(emojiString)"
        }
    }
    
    func stringRepresentationToOneDecimalPlace(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }
    
    private func failureReports(_ scenarioReports: [ScenarioReport]) -> [FailureReport] {
        var failures: [FailureReport] = []
        for report in scenarioReports {
            switch report {
            case .scenario(let scenario, let scenarioResult):
                if case .failure(let failureResult) = scenarioResult {
                    failures.append(FailureReport(scenario: scenario, failureResults: [failureResult]))
                }
            case .scenarioOutline(let scenario, let results), .scenarioPermutations(let scenario, let results):
                var failureResults: [ScenarioFailure] = []
                for scenarioResult in results {
                    if case .failure(let error) = scenarioResult.result {
                        failureResults.append(error)
                    }
                }
                if !failureResults.isEmpty {
                    failures.append(FailureReport(scenario: scenario, failureResults: failureResults))
                }
            }
        }
        return failures
    }
    
    func failureReport() -> String? {
        guard let scenarioReports = self.scenarioReports else {
            return nil
        }
        var summaryText = "\nFailures\n"
        for failureReport in failureReports(scenarioReports) {
            summaryText += "\t\(failureReport.scenario.name) failed because:\n"
            for failure in failureReport.failureResults {
                summaryText += "\t\t-> \(failure.description)\n"
            }
        }
        return summaryText
    }
    
    func summary() -> String {
        var summaryText = ""
        if let failureReport = self.failureReport() {
            summaryText += failureReport
        }
        summaryText += "\nSummary\n"
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

extension TestReporter {
    func assert() {
        XCTAssert(boolValue)
    }
}

private extension TestReporter {
    
    private func reportUsingSlack(webHookURL: URL, message: String) {
        let request = slackRequest(webHookURL: webHookURL, message: message)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpStatus = response as? HTTPURLResponse, let data = data, error == nil else {
                if let error = error {
                    print(error.localizedDescription) // TODO: Log error
                }
                return
            }
            if httpStatus.statusCode != 200 {
                let statusCode = httpStatus.statusCode
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Status code \(statusCode): \(responseString)")
                }
            }
        }
        task.resume()
    }
    
    private func slackRequest(webHookURL: URL, message: String) -> URLRequest {
        var request = URLRequest(url: webHookURL)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = "payload={\"text\": \"\(message)\"}".data(using: .utf8)
        return request
    }
    
}
