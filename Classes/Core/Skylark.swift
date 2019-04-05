//
//  Skylark.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation
import XCTest

extension TestExecutionResultReporter {
    func assert() {
        XCTAssert(boolValue)
    }
}

public class Skylark {
    
    private let configurationService: ConfigurationService = Services.configuration
    private var stepResolutionService: StepResolutionService?
    
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
    }
    
    private func initialiseStepResolver(testCase: XCTestCase, initialContext: Screen.Identifier?) {
        switch configurationService.configuration() {
        case .success(let configuration):
            let initialContext = initialContext ?? configuration.application.initialScreen ?? ""
            stepResolutionService = Services.stepResolution(context: initialContext, model: configuration, testCase: testCase)
        case .failure(let error):
            print(error)
        }
    }
    
    /// Instantiates an instance of the test runner
    public static func testRunner(testCase: XCTestCase, context: String? = nil) -> Skylark {
        let skylark = Skylark()
        skylark.register(testCase: testCase)
        skylark.initialiseStepResolver(testCase: testCase, initialContext: context)
        return skylark
    }
    
    /// Registers an XCTestCase, enabling the test runner to wait for expectations.
    public func register(testCase: XCTestCase) {
        self.testCase = testCase
    }
    
    /// Retrieves an evaluable which can be executed to run the test and determine whether or not it passed
    func evaluable(for step: String) -> Evaluable? {
        guard let condition = stepResolutionService?.resolve(step: step) else {
            // Couldn't find a direct match so let's see whether a step for a different Gherkin clause matches
            for prefix in ["given that", "given", "when", "then", "and", "or", "but"] { // ordering important
                if step.starts(with: prefix) {
                    let stepIndexAfterPrefix = step.index(step.startIndex, offsetBy: prefix.count)
                    let stepWithoutPrefix = String(step[stepIndexAfterPrefix..<step.endIndex])
                    let trimmedStepWithoutPrefix = stepWithoutPrefix
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return stepResolutionService?.resolve(step: trimmedStepWithoutPrefix)
                }
            }
            return nil
        }
        return condition
    }
    
    public func register(step: String, block: (() -> Void)? = nil) {
        let evaluable = SimpleStep({
            block?() // If there is no action to perform then step passes
            return true
        })
        stepResolutionService?.register(step: step, evaluable: evaluable)
    }
    
    public func registerFunction(for step: String, function: @escaping () -> Bool) {
        let evaluable = SimpleStep({
            return function()
        })
        stepResolutionService?.register(step: step, evaluable: evaluable)
    }
    
    public func register(step: String, evaluable: Evaluable) {
        stepResolutionService?.register(step: step, evaluable: evaluable)
    }
    
    public func setContext(_ contextId: String) {
        _ = Services.contextManagement(context: contextId)
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
    
    /// Executes the scenarios in the specified file
    public func test(featureFile fileName: String, launchArguments: [String] = []) {
        
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
        guard let featureFileData = try? Data(contentsOf: locatedFeatureFileURL, options: []) else {
                print("No data found in file \(fileName).\(featureExtension)")
                XCTAssertTrue(false, "No data found in file \(fileName).\(featureExtension)")
                return
        }
        test(featureFileData: featureFileData, launchArguments: launchArguments)
    }
    
    public func test(featureFileContent: String, launchArguments: [String] = []) {
        guard let featureFileData = featureFileContent.data(using: .utf8) else { return }
        test(featureFileData: featureFileData, launchArguments: launchArguments)
    }
    
    public func test(scenario: String, launchArguments: [String] = []) {
        launch = launchRoutine(launchArguments: launchArguments)
        let parsedLaunchArgs = launchArguments.compactMap({ LaunchArguments(rawValue: $0) })
        let featureFileParsingService = FeatureFileParsingService()
        let scenariosResult = featureFileParsingService.scenarios(from: scenario)
        switch scenariosResult {
        case .success(let scenarios):
            if let stepResolver = stepResolutionService {
                let executor = ScenarioExecutionService(stepResolver: stepResolver, arguments: parsedLaunchArgs)
                let executionResult = executor.execute(scenarios: scenarios)
                for scenarioReport in executionResult {
                    print(scenarioReport)
                }
                let reporter = TestExecutionResultReporter(scenarioReports: executionResult)
                reporter.assert()
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
    
    /// Executes the specified scenario
    public func test(featureFileData: Data, launchArguments: [String] = []) {
        launch = launchRoutine(launchArguments: launchArguments)
        let parsedLaunchArgs = launchArguments.compactMap({ LaunchArguments(rawValue: $0) })
        let featureFileParsingService = FeatureFileParsingService()
        let parsingResult = featureFileParsingService.parse(featureFileData)
        switch parsingResult {
        case .success(let feature):
            if let stepResolver = stepResolutionService {
                let executor = ScenarioExecutionService(stepResolver: stepResolver, arguments: parsedLaunchArgs)
                let executionResult = executor.execute(feature: feature)
                print(executionResult)
                XCTAssert(executionResult.result.boolValue)
            }
        case .failure(let error):
            XCTFail(error.localizedDescription)
        }
    }
}

// Private API
private extension Skylark {
    
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
    
        let isDisplayedBlock: () -> Bool = {
            var elementDisplayedResult: [Bool] = []
            for elementType in page.elements.keys {
                guard let elementsOfType = page.elements[elementType] else { continue }
                for elementOfType in elementsOfType {
                    guard let query = elementType.xcuiElement else { continue }
                    var element = query[elementOfType.value]
                    
                    switch elementType {
                    case .cells:
                        element.scrollToCell()
                    case .text:
                        let predicate = NSPredicate(format: "label CONTAINS[cd] '\(elementOfType.value)'")
                        element = query.matching(predicate).firstMatch
                    default:
                        element.scrollToElement()
                    }

                    let exists = (elementType == .navigationBars )
                        ? NSPredicate(format: "identifier LIKE '\(elementOfType.value)'")
                        : NSPredicate(format: "exists == YES")
                    
                    if let expectation = self.testCase?.expectation(for: exists, evaluatedWith: element, handler: nil) {
                        self.testCase?.wait(for: [expectation], timeout: self.timeout, enforceOrder: true)
                    }
                    
                    elementDisplayedResult.append(element.exists)
                }
            }
            let overallResult = elementDisplayedResult.reduce(true, { (previousResult, nextResult) -> Bool in
                return previousResult && nextResult
            })
            return overallResult
        }
        for stepDefinition in stepDefinitions {
            let parameterisedStep = stepDefinition.replacingOccurrences(of: "$PARAMETER", with: page.name.lowercased())
            registerFunction(for: parameterisedStep, function: isDisplayedBlock)
        }
    }
    
    // Register steps for screen elements
    func registerStepsForElements(for element: (key: String, value: String), page: String? = nil,
                                  elementType: ElementType, stepDefinitions: [String: [String]]) {
        let query = elementType.xcuiElement
        let isDisplayedBlock: () -> Bool = {
            guard let query = query else { return false }
            var elem = query[element.value]
            
            switch elementType {
            case .cells:
                elem.scrollToCell()
            case .text:
                let predicate = NSPredicate(format: "label CONTAINS[cd] '\(element.value)'")
                elem = query.matching(predicate).firstMatch
            default:
                elem.scrollToElement()
            }
            
            if elementType == ElementType.cells {
                elem.scrollToCell()
            } else {
                elem.scrollToElement()
            }
           
            let exists = (query == XCUIApplication().navigationBars)
                ? NSPredicate(format: "identifier LIKE '\(element.value)'")
                : NSPredicate(format: "exists == YES")
            
            if let expectation = self.testCase?.expectation(for: exists, evaluatedWith: elem, handler: nil) {
                self.testCase?.wait(for: [expectation], timeout: self.timeout, enforceOrder: true)
            }
            return elem.exists
        }
        if let existenceSteps = stepDefinitions["existence"] {
            for existenceStep in existenceSteps {
                registerFunction(for: existenceStep.replacingOccurrences(of: "$PARAMETER", with: element.key),
                         function: isDisplayedBlock)
            }
        }
        let tapBlock: () -> Void = {
            guard let query = query else { return }
            var elem = query[element.value]
            if elementType == .cells {
                elem.scrollToCell()
            }
            if !elem.exists {
                elem = query[element.value.capitalized]
            }

            elem.tap()
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
                                         elementType: xcuiElementQuery, stepDefinitions: stepDefinitions)
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
    
    /// Tag expression describing which tagged scenarios should be executed.
    private func tagExpression() -> String? {
        for index in 1..<CommandLine.arguments.count
            where CommandLine.arguments[index] == "--tags" && index + 1 < CommandLine.arguments.count {
                return CommandLine.arguments[index + 1]
        }
        return nil
    }
}
