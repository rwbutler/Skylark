//
//  ScenarioExecutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/12/19.
//

import Foundation
import XCTest

class ScenarioExecutionService: ExecutionService {
    
    private let contextManagement: ContextManagementService
    var launchArgs: [LaunchArguments] = []
    var setUps: [SetUp] = []
    private let stepResolver: StepResolutionService
    var tearDowns: [TearDown] = []
    
    init(contextManagement: ContextManagementService, stepResolver: StepResolutionService) {
        self.contextManagement = contextManagement
        self.stepResolver = stepResolver
    }
    
    // Executes a feature
    func execute(feature: Feature, retryCount: Int = 0) -> TestReport {
        if !launchArgs.contains(where: { $0 == .resetEachScenario }) {
            tearDown(for: .simulatorReset)
            launch(launchArguments: launchArgs)()
            setUp(for: .simulatorReset)
        }
        setUp(for: .eachFeature)
        let scenarioResults: [ScenarioReport] = execute(scenarios: feature.scenarios,
                                                        additionalTags: feature.tags, retryCount: retryCount)
        tearDown(for: .eachFeature)
        let overallResult = featureResult(from: scenarioResults)
        let report =  FeatureReport(feature: feature, scenarioReports: scenarioResults, result: overallResult)
        return .feature(report)
    }
    
    func execute(scenarios: [Scenario], retryCount: Int = 0) -> TestReport {
        return .scenarios(execute(scenarios: scenarios, additionalTags: nil, retryCount: retryCount))
    }
    
    private func execute(scenarios: [Scenario], additionalTags: [Tag]? = nil, retryCount: Int = 0) -> [ScenarioReport] {
        let outlineParser = ScenarioOutlineParser()
        var results: [ScenarioReport] = []
        
        if !launchArgs.contains(where: { $0 == .resetEachScenario }) {
            tearDown(for: .simulatorReset)
            launch(launchArguments: launchArgs)()
            setUp(for: .simulatorReset)
        }
        
        for scenario in scenarios {
            guard let tagExpression = self.tagExpression(),
                let conditionalExecutionService = ScenarioTagsService(tagExpression: tagExpression) else {
                    let result: ScenarioResult = .notExecuted(.unrecognizedTagExpression)
                    let scenarioResult = ScenarioReport.scenario(scenario, result: result)
                    results.append(scenarioResult)
                    TestReporter.report(scenarioReport: scenarioResult)
                    continue
            }
            let scenarioTagExpr = scenario.tagExpression ?? ""
            var scenarioTags = scenario.tags ?? []
            if let additionalTags = additionalTags {
                scenarioTags.append(contentsOf: additionalTags)
            }
            
            // Check whether the scenario should be executed based on tags.
            let shouldExecuteScenario = conditionalExecutionService.shouldExecuteScenario(tags: scenarioTags)
            if !shouldExecuteScenario {
                let nonExecutionResult: ScenarioResult = .notExecuted(
                    .tagMismatch(tagExpr: scenarioTagExpr, testRunnerTagExpr: tagExpression)
                )
                let result = ScenarioReport.scenario(scenario, result: nonExecutionResult)
                results.append(result)
                TestReporter.report(scenarioReport: result)
                continue
            }
            
            switch scenario.type {
            case .scenario:
                let result = scenarioReport(name: scenario.name, scenarioText: scenario.text, retryCount: retryCount)
                let scenarioResult = ScenarioReport.scenario(scenario, result: result)
                results.append(scenarioResult)
                TestReporter.report(scenarioReport: scenarioResult)
            case .scenarioOutline, .scenarioPermutations:
                let scenarioTexts = outlineParser.scenariosWithExampleSubstitutions(scenario: scenario.text,
                                                                                    type: scenario.type)
                var outlineResults: [ScenarioOutlineResult] = []
                for scenarioText in scenarioTexts {
                    let result = scenarioReport(name: scenario.name, scenarioText: scenarioText, retryCount: retryCount)
                    outlineResults.append(ScenarioOutlineResult(result: result, scenarioText: scenarioText))
                }
                if case .scenarioOutline = scenario.type {
                    let result = ScenarioReport.scenarioOutline(scenario, results: outlineResults)
                    results.append(result)
                    TestReporter.report(scenarioReport: result)
                }
                if case .scenarioPermutations = scenario.type {
                    let result = ScenarioReport.scenarioPermutations(scenario, results: outlineResults)
                    results.append(result)
                    TestReporter.report(scenarioReport: result)
                }
            }
        }
        return results
    }
    
    func evaluable(for step: String) -> Evaluable? {
        return stepResolver.resolve(step: step)
    }
    
    func evaluate(scenarioName: String, scenarioText: String) -> ScenarioResult {
        let currentContext = contextManagement.currentContext().context.name
        let emojiString = Skylark.emojiInOutput ? " 🏃‍♂️\n" : ".\n"
        let steps: [String] = scenarioText.split(separator: "\n").map({ String($0) })
        
        for step in steps {
            let trimmedStep = step.lowercased().trimmingCharacters(in: CharacterSet.whitespaces)
            if let eval = evaluable(for: trimmedStep) {
                let executableStep = GherkinStep(evaluable: eval, text: step)
                setUp(for: .eachStep)
                setUp(scenario: scenarioName, step: executableStep.text)
                let output = "\nRunning step '\(trimmedStep)' in '\(currentContext)' context\(emojiString)"
                               print(output)
                let result = executableStep.evaluable.evaluate()
                tearDown(for: .eachStep)
                tearDown(scenario: scenarioName, step: executableStep.text)
                if !result {
                    return .failure(.stepFailure(executableStep.text))
                }
            } else {
                return .failure(.noMatchingStep(step))
            }
        }
        return .success
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
    
    func launch(launchArguments: [LaunchArguments]) -> () -> Void {
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
            self.contextManagement.reset()
        }
        return launch
    }
    
    private func setUp(for trigger: Trigger) {
        let setUpsToExecute = setUps.filter { $0.trigger == trigger }
        setUpsToExecute.forEach { $0.execute() }
    }
    
    private func setUp(scenario name: String, step: String? = nil) {
        let setUpsToExecute  = setUps.filter {
            if case let .scenario(scenarioName) = $0.trigger, scenarioName == name, step == nil {
                return true
            }
            if let step = step {
                let nonPrefixedStep = stepWithoutGherkinPrefix(step: step)
                if case let .step(scenarioName, stepText) = $0.trigger, scenarioName == name,
                    (stepText == step || stepText == nonPrefixedStep) {
                    return true
                }
            }
            return false
        }
        setUpsToExecute.forEach { $0.execute() }
    }
    
    func scenarioReport(name: String, scenarioText: String, retryCount: Int = 0) -> ScenarioResult {
        if launchArgs.contains(where: { $0 == .resetEachScenario }) {
            launch(launchArguments: launchArgs)()
            setUp(for: .simulatorReset)
        }
        setUp(for: .eachScenario)
        setUp(scenario: name)
        print("\nTesting scenario '\(name)':\n")
        let result = evaluate(scenarioName: name, scenarioText: scenarioText)
        var flakyResults: [ScenarioResult] = []
        if case .failure = result, retryCount > 0 {
            flakyResults.append(result)
            for _ in 0..<retryCount {
                print("\nRe-testing scenario '\(name)':\n")
                if launchArgs.contains(where: { $0 == .resetEachScenario }) {
                    launch(launchArguments: launchArgs)()
                    setUp(for: .simulatorReset)
                }
                setUp(for: .eachScenario)
                setUp(scenario: name)
                let result = evaluate(scenarioName: name, scenarioText: scenarioText)
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
    
    func stepIsPrefixedByConjunction(step: String) -> Bool {
        let conjunctions = ["and", "or", "but"]
        for conjunction in conjunctions where step.starts(with: conjunction) {
            return true
        }
        return false
    }
    
    func stepWithoutGherkinPrefix(step: String) -> String {
        let prefixes = ["given that", "given", "when", "then", "and", "or", "but"]
        for prefix in prefixes where step.starts(with: prefix) {
            let stepIndexAfterPrefix = step.index(step.startIndex, offsetBy: prefix.count)
            let stepWithoutPrefix = String(step[stepIndexAfterPrefix..<step.endIndex])
            return stepWithoutPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return step
    }
    
    private func tagExpression() -> String? {
        for index in 1..<CommandLine.arguments.count
            where CommandLine.arguments[index] == "--tags" && index + 1 < CommandLine.arguments.count {
                return CommandLine.arguments[index + 1]
        }
        return nil
    }
    
    private func tearDown(for trigger: Trigger) {
        let tearDownsToExecute = tearDowns.filter { $0.trigger == trigger }
        tearDownsToExecute.forEach { $0.execute() }
    }
    
    private func tearDown(scenario name: String, step: String? = nil) {
        let tearDownsToExecute  = tearDowns.filter {
            if case let .scenario(scenarioName) = $0.trigger, scenarioName == name, step == nil {
                return true
            }
            if let step = step {
                let nonPrefixedStep = stepWithoutGherkinPrefix(step: step)
                if case let .step(scenarioName, stepText) = $0.trigger, scenarioName == name,
                    (stepText == step || stepText == nonPrefixedStep) {
                    return true
                }
            }
            return false
        }
        tearDownsToExecute.forEach { $0.execute() }
    }
    
}
