//
//  Skylark.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation
import XCTest

public class Skylark {
    
    // MARK: State
    private var launch: () -> Void = {
        let application = XCUIApplication()
        if application.state == .runningForeground {
            application.terminate()
        }
        application.launch()
    }
    private var retryFailingScenariosCount: Int = 0
    private var stepTextToEvaluableStep: [String: Step] = [:]
    private var testCase: XCTestCase?
    private let timeout: TimeInterval
    
    private init(timeout: TimeInterval = 10.0) {
        self.timeout = timeout
        self.retryFailingScenariosCount = scenarioRetryCount()
        registerStepsFromConfiguration()
    }
    
    /// Instantiates an instance of the test runner
    public static func testRunner(testCase: XCTestCase) -> Skylark {
        let skylark = Skylark()
        skylark.register(testCase: testCase)
        return skylark
    }
    
    /// Registers an XCTestCase, enabling the test runner to wait for expectations.
    public func register(testCase: XCTestCase) {
        self.testCase = testCase
    }
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func scenario(text: String) -> Scenario? {
        
        let steps: [String] = text.lowercased().split(separator: "\n").map({ String($0) })
        
        var given: Step?, when: Step?, then: Step?
        var parsingFlags: GherkinSteps = []
        
        for step in steps {
            let sanitisedStep = step.trimmingCharacters(in: CharacterSet.whitespaces).lowercased()
            
            // Populate parsing flags
            guard !sanitisedStep.starts(with: "#") else { continue } // Ignore comments
            if sanitisedStep.starts(with: GherkinSteps.given.description) {
                if parsingFlags == .given {
                    parsingFlags.formUnion(.and)
                } else {
                    parsingFlags = [.given]
                }
            }
            if sanitisedStep.starts(with: GherkinSteps.when.description) {
                if parsingFlags == .when {
                    parsingFlags.formUnion(.and)
                } else {
                    parsingFlags = [.when]
                }
            }
            if sanitisedStep.starts(with: GherkinSteps.then.description) {
                if parsingFlags == .then {
                    parsingFlags.formUnion(.and)
                } else {
                    parsingFlags = [.then]
                }
            }
            if sanitisedStep.starts(with: GherkinSteps.and.description) { parsingFlags.formUnion(.and) }
            if sanitisedStep.starts(with: GherkinSteps.or.description) { parsingFlags.formUnion(.or) }
            if sanitisedStep.starts(with: GherkinSteps.but.description) { parsingFlags.formUnion(.but) }
            
            if let currentStep = evaluable(for: sanitisedStep) {
                switch parsingFlags {
                case .given:
                    given = currentStep
                case .when:
                    when = currentStep
                case .then:
                    then = currentStep
                case [.given, .and]:
                    guard let previousStep = given else {
                        XCTAssert(false, "No matching step found for GIVEN clause.")
                        return nil
                    }
                    given = AndStep(lhs: previousStep, rhs: currentStep)
                case [.given, .but]:
                    guard let previousStep = given else {
                        XCTAssert(false, "No matching step found for GIVEN clause.")
                        return nil
                    }
                    let butStep = NegatedStep(expr: currentStep)
                    given = AndStep(lhs: previousStep, rhs: butStep)
                case [.given, .or]:
                    guard let previousStep = given else {
                        XCTAssert(false, "No matching step found for GIVEN clause.")
                        return nil
                    }
                    given = OrStep(lhs: previousStep, rhs: currentStep)
                case [.when, .and]:
                    guard let previousStep = when else {
                        XCTAssert(false, "No matching step found for WHEN clause.")
                        return nil
                    }
                    when = AndStep(lhs: previousStep, rhs: currentStep)
                case [.when, .but]:
                    guard let previousStep = when else {
                        XCTAssert(false, "No matching step found for WHEN clause.")
                        return nil
                    }
                    let butStep = NegatedStep(expr: currentStep)
                    given = AndStep(lhs: previousStep, rhs: butStep)
                case [.when, .or]:
                    guard let previousStep = when else {
                        XCTAssert(false, "No matching step found for WHEN clause.")
                        return nil
                    }
                    when = OrStep(lhs: previousStep, rhs: currentStep)
                case [.then, .and]:
                    guard let previousStep = then else {
                        XCTAssert(false, "No matching step found for THEN clause.")
                        return nil
                    }
                    then = AndStep(lhs: previousStep, rhs: currentStep)
                case [.then, .but]:
                    guard let previousStep = then else {
                        XCTAssert(false, "No matching step found for THEN clause.")
                        return nil
                    }
                    let butStep = NegatedStep(expr: currentStep)
                    given = AndStep(lhs: previousStep, rhs: butStep)
                case [.then, .or]:
                    guard let previousStep = then else {
                        XCTAssert(false, "No matching step found for THEN clause.")
                        return nil
                    }
                    then = OrStep(lhs: previousStep, rhs: currentStep)
                default:
                    break
                }
            } else {
                XCTAssert(false, "No matching step found for \(sanitisedStep).")
                return nil
            }
        }
        guard let givenCondition = given, let thenCondition = then else { return nil }
        return Scenario(scenarioText: text, given: givenCondition, when: when, then: thenCondition)
    }
    
    /// Retrieves an evaluable which can be executed to run the test and determine whether or not it passed
    func evaluable(for step: String) -> Step? {
        guard let condition = stepTextToEvaluableStep[step.lowercased()] else {
            // Couldn't find a direct match so let's see whether a step for a different Gherkin clause matches
            for prefix in ["given that", "given", "when", "then", "and", "or", "but"] { // ordering important
                if step.starts(with: prefix) {
                    let stepIndexAfterPrefix = step.index(step.startIndex, offsetBy: prefix.count)
                    let stepWithoutPrefix = String(step[stepIndexAfterPrefix..<step.endIndex])
                    let trimmedStepWithoutPrefix = stepWithoutPrefix
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    return stepTextToEvaluableStep[trimmedStepWithoutPrefix]
                }
            }
            return nil
        }
        return condition
    }
    
    public func register(step: String, block: (() -> Void)? = nil) {
        stepTextToEvaluableStep[step.lowercased()] = SimpleStep({
            block?() // If there is no action to perform then step passes
            return true
        })
    }
    
    public func registerFunction(for step: String, function: @escaping () -> Bool) {
        stepTextToEvaluableStep[step.lowercased()] = SimpleStep({
            return function()
        })
    }
    
    func register(step: String, evaluable: Step) {
        stepTextToEvaluableStep[step.lowercased()] = evaluable
    }
    
    /// Executes the scenarios in the specified file
    public func test(featureFile fileName: String, launchArguments: [String] = []) {
        launch = launchRoutine(launchArguments: launchArguments)
        var featureFileURL: URL?
        let featureExtension: String = "\(FileExtension.feature)"
        for aBundle in Bundle.allBundles {
            if let featureFileURLInBundle = aBundle.url(forResource: fileName, withExtension: featureExtension) {
                featureFileURL = featureFileURLInBundle
                break
            }
        }
        guard let locatedFeatureFileURL = featureFileURL else {
            XCTAssertTrue(false, "No file named \(fileName).\(featureExtension) exists")
            return
        }
        guard let featureFileData = try? Data(contentsOf: locatedFeatureFileURL, options: []),
            let featureFileContents = String(data: featureFileData, encoding: .utf8)?.lowercased() else {
                print("No data found in file \(fileName).\(featureExtension)")
                XCTAssertTrue(false, "No data found in file \(fileName).\(featureExtension)")
                return
        }
        
        // Define regular expression to split feature file into individual scenarios
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: "\n\n(?! *examples:)", options: [])
        let featureFileRange = NSRange(location: 0, length: featureFileContents.utf16.count)
        let matches = regex.matches(in: featureFileContents,
                                    range: featureFileRange)
        
        // Split feature file into individual scenatrios using the specified regular expression
        let scenarios = zip(matches, matches.dropFirst().map {
            Optional.some($0) } + [nil]).compactMap { current, next -> String? in
                let range = current.range(at: 0)
                let start = String.UTF16Index(encodedOffset: range.location)
                let end = next.map { $0.range(at: 0) }.map { String.UTF16Index(encodedOffset: $0.location) }
                    ?? String.UTF16Index(encodedOffset: featureFileContents.utf16.count)
                return String(featureFileContents.utf16[start..<end])?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var scenariosToEvaluate: [Scenario] = []
        
        // Iterate scenarios, converting each to an evaluable to execute the test
        for scenarioText in scenarios where shouldExecuteScenario(scenario: scenarioText) {
            if let startIndex = scenarioText.range(of: "given")?.lowerBound {
                let stepsText = String(scenarioText[startIndex..<scenarioText.endIndex])
                launch()
                let scenarios = parameterisedScenarios(scenarioText: stepsText)
                scenariosToEvaluate.append(contentsOf: scenarios)
            }
        }
        let result = evaluate(scenarios: scenariosToEvaluate)
        for failedScenario in result.flakyScenarios {
            print("The following scenario failed:\n\n\(String(describing: failedScenario.scenarioText))")
        }
        print(result)
        XCTAssert(result.passed)
    }
    
    func launchRoutine(launchArguments: [String]) -> () -> Void {
        let launch: () -> Void = {
            let application = XCUIApplication()
            if application.state == .runningForeground {
                application.terminate()
            }
            application.launchArguments = launchArguments
            application.launch()
        }
        return launch
    }
    
    /// Executes the specified scenario
    public func test(scenario scenarioText: String, reset: Bool = false) {
        launch()
        let scenarios = parameterisedScenarios(scenarioText: scenarioText)
        let result = evaluate(scenarios: scenarios)
        for failedScenario in result.flakyScenarios {
           print("The following scenario failed:\n\n\(String(describing: failedScenario.scenarioText))")
        }
        print(result)
        XCTAssert(result.passed)
    }
}

// Private API
private extension Skylark {
    
    // Takes a scenario template and yields scenarios with parameters filled in
    func parameterisedScenarios(scenarioText: String) -> [Scenario] {
        let parser = ScenarioOutlineParser()
        var result: [Scenario] = []
        if scenarioText.lowercased().contains("scenario outline:")
            || scenarioText.lowercased().contains("scenario template:") {
            let scenarios = parser.scenariosWithExampleSubstitutions(scenario: scenarioText, outline: .outline)
            let evaluableScenarios = scenarios.compactMap({ scenario(text: $0) })
            result.append(contentsOf: evaluableScenarios)
        } else if scenarioText.lowercased().contains("scenario permutations:") {
            let scenarios = parser.scenariosWithExampleSubstitutions(scenario: scenarioText, outline: .permutations)
            let evaluableScenarios = scenarios.compactMap({ scenario(text: $0) })
            result.append(contentsOf: evaluableScenarios)
        } else if let evaluableScenario = scenario(text: scenarioText) {
            result.append(evaluableScenario)
        }
        return result
    }
    
    /// Evaluates whether the specified scenarios passed
    func evaluate(scenarios: [Scenario]) -> SkylarkResult {
        var scenariosPassed: [Scenario] = []
        var scenariosFailed: [Scenario] = []
        var scenariosFlaky: [Scenario] = []
        
        for scenario in scenarios {
            let firstRunResult = scenario.evaluate()
            guard !firstRunResult else {
                scenariosPassed.append(scenario)
                continue
            }
            // Test failed - retry the specified number of times
            var retryResults: [Bool] = []
            for _ in 0..<retryFailingScenariosCount {
                launch()
                retryResults.append(scenario.evaluate())
            }
            let numberRequiredSuccesses: Int = Int((Double(retryResults.count) / Double(2.0)).rounded(.up))
            let numberOfSuccesses = retryResults.filter({ $0 == true }).count
            
            let passed = numberRequiredSuccesses <= numberOfSuccesses
            if passed {
                scenariosFlaky.append(scenario)
            } else {
                scenariosFailed.append(scenario)
            }
        }
        return SkylarkResult(passedScenarios: scenariosPassed, failedScenarios: scenariosFailed,
                             flakyScenarios: scenariosFlaky)
    }
    
    /// Retrieves the current bundle
    private func currentBundle() -> Bundle {
        return Bundle(for: type(of: self))
    }
    
    /// Registers keyboard step definitions
    private func registerStepDefinitionsForKeyboard(page: String? = nil, stepDefinitions: [String]) {
        let isDisplayedBlock: () -> Void = {
            let element = XCUIApplication().keyboards.firstMatch
            let exists = NSPredicate(format: "exists == YES")
            self.testCase?.expectation(for: exists, evaluatedWith: element, handler: nil)
            self.testCase?.waitForExpectations(timeout: self.timeout, handler: nil)
        }
        for stepDefinition in stepDefinitions {
            register(step: stepDefinition, block: isDisplayedBlock)
        }
    }
    
    /// Registers page step definitions
    private func registerStepDefinitionsForPage(page: Page, stepDefinitions: [String]) {
        let isDisplayedBlock: () -> Void = {
            
            for elementType in page.elements.keys {
                for elementOfType in page.elements[elementType]! {
                    let element = elementType.xcuiElement[elementOfType.value]
                    element.scrollToElement()
                    let exists = (elementType == .navigationBars )
                        ? NSPredicate(format: "identifier LIKE '\(elementOfType.value)'")
                        : NSPredicate(format: "exists == YES")
                    self.testCase?.expectation(for: exists, evaluatedWith: element, handler: nil)
                    self.testCase?.waitForExpectations(timeout: self.timeout, handler: nil)
                }
            }
        }
        for stepDefinition in stepDefinitions {
            let parameterisedStep = stepDefinition.replacingOccurrences(of: "$PARAMETER", with: page.name.lowercased())
            register(step: parameterisedStep, block: isDisplayedBlock)
        }
    }
    
    // Register steps for screen elements
    func registerStepsForElements(for element: (key: String, value: String), page: String? = nil,
                                  query: XCUIElementQuery, stepDefinitions: [String: [String]]) {
        let isDisplayedBlock: () -> Void = {
            let elem = query[element.value]
            elem.scrollToElement()
            let exists = (query == XCUIApplication().navigationBars)
                ? NSPredicate(format: "identifier LIKE '\(element.value)'")
                : NSPredicate(format: "exists == YES")
            self.testCase?.expectation(for: exists, evaluatedWith: elem, handler: nil)
            self.testCase?.waitForExpectations(timeout: self.timeout, handler: nil)
        }
        if let existenceSteps = stepDefinitions["existence"] {
            for existenceStep in existenceSteps {
                register(step: existenceStep.replacingOccurrences(of: "$PARAMETER", with: element.key),
                         block: isDisplayedBlock)
            }
        }
        let tapBlock: () -> Void = {
            let element = query[element.value]
            element.tap()
        }
        if let interactionSteps = stepDefinitions["interaction"] {
            for interactionStep in interactionSteps {
                register(step: interactionStep.replacingOccurrences(of: "$PARAMETER", with: element.key),
                         block: tapBlock)
            }
        }
    }
    
    /// Registers all step definitions from configuration
    func registerStepsFromConfiguration() {
        let stepParser = StepParser()
        guard let stepDefinitions = stepParser.parse(bundle: currentBundle()) else {
            return
        }
        for stepDefinition in stepDefinitions {
            switch stepDefinition {
            case .element(let pageName, let element, let xcuiElementQuery, let stepDefinitions):
                registerStepsForElements(for: element, page: pageName,
                                         query: xcuiElementQuery, stepDefinitions: stepDefinitions)
            case .keyboard(let pageName, let stepDefinitions):
                registerStepDefinitionsForKeyboard(page: pageName, stepDefinitions: stepDefinitions)
            case .page(let page, let stepDefinitions):
                registerStepDefinitionsForPage(page: page, stepDefinitions: stepDefinitions)
            }
        }
    }
    
    /// Reads number of times to retry failing scenarios
    func scenarioRetryCount() -> Int {
        for index in 1..<CommandLine.arguments.count
            where CommandLine.arguments[index] == "--retry"
                && index + 1 < CommandLine.arguments.count {
                    if let retryCount = Int(CommandLine.arguments[index + 1]) {
                        return retryCount
                    }
        }
        return 0
    }
    
    /// Evaluates whether the supplied scenario should be executed given the current tag expression.
    func shouldExecuteScenario(scenario: String) -> Bool {
        guard let tagExpression = tagExpression() else { return true }
        
        // No scenarios will be executed in the tag expression could not be evaluated.
        return ScenarioTagsService(tagExpression: tagExpression)?.shouldExecuteScenario(scenario) ?? false
    }
    
    /// Tag expression describing which tagged scenarios should be executed.
    private func tagExpression() -> String? {
        for index in 1..<CommandLine.arguments.count
            where CommandLine.arguments[index] == "--tags" && index + 1 < CommandLine.arguments.count {
                return CommandLine.arguments[index + 1]
        }
        return nil
    }
    
}