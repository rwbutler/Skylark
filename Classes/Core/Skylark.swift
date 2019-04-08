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
    //private var retryFailingScenariosCount: Int = 0
    private var stepTextToEvaluableStep: [String: Step] = [:]
    private var testCase: XCTestCase?
    private let timeout: TimeInterval
    
    private init(timeout: TimeInterval = 10.0) {
        self.timeout = timeout
    }
    
    private func initialiseStepResolver(testCase: XCTestCase, initialContext: Screen.Identifier?) {
        switch configurationService.configuration() {
        case .success(let configuration):
            let initialContext = initialContext ?? configuration.application.initialScreen ?? ""
            stepResolutionService = Services.stepResolution(context: initialContext,
                                                            model: configuration, testCase: testCase)
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
