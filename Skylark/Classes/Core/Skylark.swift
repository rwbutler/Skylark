//
//  Skylark.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation
import XCTest

public class Skylark {
    
    // MARK: - Type Definitions
    
    /// Framework constants.
    enum Constants {
        static let frameworkName = "Skylark"
        static let configurationType: FileExtension = .json
    }
    
    /// Requirements in order for the test runner to execute tests.
    struct Dependencies {
        let contextManagementService: ContextManagementService
        let executionService: ExecutionService
        let stepResolutionService: StepResolutionService
    }
    
    /// Sink to which the framework should send output.
    public typealias Output = SkylarkOutput
    
    // MARK: - Dependencies
    
    /// Parses and retains framework configuration.
    private let configurationService = Services.configuration
    
    /// Manages state transitions between contexts.
    private var contextManagementService: ContextManagementService?
    
    /// Executes the scenarios contained within feature files.
    private var executionService: ExecutionService?
    
    /// Attempts to resolve resources from available bundles.
    private let resourceResolutionService = Services.resourceResolution
    
    /// Resolves step definitions to evaluable expressions.
    private var stepResolutionService: StepResolutionService?
    
    // MARK: - State
    
    /// Context representing the state of the application when launched.
    private var initialContextId: Context.Identifier?
    
    /// Whether or not to include emoji in output.
    public static var emojiInOutput: Bool = true
    
    private static var isObserving = false
    public var outputs: [Output] {
        get {
            return type(of: self).outputs
        }
        set {
            type(of: self).outputs = newValue
        }
    }
    
    /// Sink to which the framework should send output.
    public static var outputs: [Output] = [.print]
    
    /// Options for how the framework should report to the user.
    public static var reportingOptions: ReportingOptions = .always
    
    /// Set Up closures to be executed prior to scenarios.
    private var setUps: [SetUp] = []
    
    /// Tear Down closures to be executed following scenarios.
    private var tearDowns: [TearDown] = []
    
    /// The `XCTestCase` to be used when executing tests. TODO: May no longer be required?
    private var testCase: XCTestCase?
    
    /// Test report per invocation of test functions, retained in order to report on all test
    /// results on execution of entire test suite.
    private static var testReports: [TestReport] = []
    
    /// Observes test execution progress for reporting. TODO: May no longer be required?
    private static let testObserver = TestObserver()
    
    private let timeout: TimeInterval
    
    private init(initialContextId: Context.Identifier? = nil, timeout: TimeInterval = 10.0) {
        self.initialContextId = initialContextId
        self.timeout = timeout
        Skylark.testObserver.addObserver(self)
    }
    
    /// Instantiates and returns an instance of the test runner.
    public static func testRunner(testCase: XCTestCase? = nil, context: Context.Identifier? = nil) -> Skylark {
        if !Skylark.isObserving {
            XCTestObservationCenter.shared.addTestObserver(Skylark.testObserver)
            Skylark.isObserving = true
        }
        let testRunner = Skylark(initialContextId: context)
        if let testCase = testCase {
            testRunner.setTestCase(testCase)
        }
        return testRunner
    }
    
    public func register(_ step: String, screen: Context.Identifier? = nil, ignoringResult: (() -> Void)? = nil) {
        let evaluable = SimpleStep({
            ignoringResult?() // If there is no action to perform then step passes
            return true
        })
        register(step, screen: screen, evaluable: evaluable)
    }
    
    public func register(_ step: String, screen: Context.Identifier? = nil, boolResult: @escaping () -> Bool) {
        let evaluable = SimpleStep({
            return boolResult()
        })
        register(step, screen: screen, evaluable: evaluable)
    }
    
    public func register(_ step: String, screen: Context.Identifier? = nil, evaluable: Evaluable) {
        stepResolutionService?.register(step: step, evaluable: evaluable, screen: screen)
    }
    
    public func context() -> ContextInstance? {
        return contextManagementService?.currentContext()
    }
    
    public func setContext(_ contextId: String) {
        contextManagementService?.setContext(identifier: contextId)
    }
    
    public func setInitialContext(_ contextId: String) {
        self.initialContextId = contextId
    }
    
    public func test(featureFile url: URL, arguments: [LaunchArguments] = []) {
        guard let featureFileData = try? Data(contentsOf: url) else {
            XCTFail("Unable to read feature file from \(url.absoluteString).")
            return
        }
        test(featureData: featureFileData, arguments: arguments)
    }
    
    /// Assigns a function to be executed prior to each test.
    public func setUp(_ trigger: Trigger = .eachScenario, setUp: @escaping () -> Void) {
        self.setUps.append(SetUp(setUp, trigger: trigger))
    }
    
    /// Assigns a function to be executed prior to each test.
    public func tearDown(_ trigger: Trigger = .eachScenario, tearDown: @escaping () -> Void) {
        self.tearDowns.append(TearDown(tearDown, trigger: trigger))
    }
    
    public func clearSetUps() {
        self.setUps.removeAll()
    }
    
    public func clearTearDowns() {
        self.tearDowns.removeAll()
    }
    
    static func reportTestSummary() {
        let reporter = TestReporter(testReports, output: outputs)
        reporter.report()
    }
    
    func setTestCase(_ testCase: XCTestCase) {
        // Check we are updating with a different XCTestCase.
        if let currentTestCase = self.testCase, currentTestCase == testCase {
            return
        }
        self.testCase = testCase
        guard isConfigured() else {
            let configurationResult = configure(with: testCase)
            switch configurationResult {
            case .success(let dependencies):
                setDependencies(dependencies)
            case .failure(let error):
                failOnConfigurationError(error)
            }
            return
        }
        stepResolutionService?.updateTestCase(testCase)
    }
    
    /// Executes the scenarios in the specified feature file.
    public func test(featureFile named: String, arguments: [LaunchArguments] = []) {
        let fileExtension = FileExtension.feature.rawValue
        guard let featureFileURL = resourceResolutionService.url(forResource: named, withExtension: fileExtension)
            else {
            XCTFail("No file named \(named).\(fileExtension) exists in the test bundle.")
            return
        }
        test(featureFile: featureFileURL, arguments: arguments)
    }
    
    /// Executes the feature file given its content represented as a `String`.
    public func test(feature: String, arguments: [LaunchArguments] = []) {
        guard let featureFileData = feature.data(using: .utf8) else {
            XCTFail("Unable to decode feature using UTF-8 character set.")
            return
        }
        test(featureData: featureFileData, arguments: arguments)
    }
    
    /// Executes the feature file given its content represented as `Data`.
    public func test(featureData: Data, arguments: [LaunchArguments] = []) {
        let retryCount = retryCountForFailingScenario()
        let featureFileParsingService = FeatureFileParsingService()
        let parsingResult = featureFileParsingService.parse(featureData)
        switch parsingResult {
        case .success(let feature):
            switch executor() {
            case .success(var executor):
                executor.launchArgs = arguments
                executor.setUps = setUps
                executor.tearDowns = tearDowns
                let testReport = executor.execute(feature: feature, retryCount: retryCount)
                addTestReport(testReport)
                let hasPassed = TestReporter.boolValue(from: testReport)
                XCTAssertTrue(hasPassed)
            case .failure(let error):
                failOnConfigurationError(error)
            }
        case .failure(let error):
            // TODO: Handle this failure in a better way.
            XCTFail(error.localizedDescription)
        }
    }
    
    /// Executes the scenario represented by the given `String`.
    public func test(scenario: String, arguments: [LaunchArguments] = []) {
        let retryCount = retryCountForFailingScenario()
        let featureFileParsingService = FeatureFileParsingService()
        let scenariosResult = featureFileParsingService.scenarios(from: scenario)
        switch scenariosResult {
        case .success(let scenarios):
            switch executor() {
            case .success(var executor):
                executor.launchArgs = arguments
                executor.setUps = setUps
                executor.tearDowns = tearDowns
                let testReport = executor.execute(scenarios: scenarios, retryCount: retryCount)
                addTestReport(testReport)
                let hasPassed = TestReporter.boolValue(from: testReport)
                XCTAssertTrue(hasPassed)
            case .failure(let error):
                failOnConfigurationError(error)
            }
        case .failure(let error):
            // TODO: Handle this failure in a better way.
            XCTFail(error.localizedDescription)
        }
    }
    
}

// Private API
private extension Skylark {
    
    private func addTestReport(_ report: TestReport) {
        type(of: self).testReports.append(report)
    }
    
    /// Configures the framework with an XCTestCase for executing 
    private func configure(with testCase: XCTestCase) -> Result<Dependencies, ConfigurationError> {
        switch configurationService.configuration() {
        case .success(let configuration):
            let initialContextId = self.initialContextId ?? configuration.application.initialContext
            
            guard let id = initialContextId, let initialContext = configuration.application.contexts[id] else {
                return .failure(.initialContextNotSpecified)
            }
            let contextManagement = Services.contextManagement(context: initialContext, model: configuration)
            let stepResolver = Services.stepResolution(contextManagement: contextManagement,
                                                       model: configuration, testCase: testCase)
            let executionService = Services.executionService(contextManagement: contextManagement,
                                                             stepResolver: stepResolver)
            let dependencies = Dependencies(contextManagementService: contextManagement,
                                            executionService: executionService, stepResolutionService: stepResolver)
            return .success(dependencies)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Guaranteed to return an executor for running tests or an error describing the problem.
    private func executor() -> Result<ExecutionService, ConfigurationError> {
        guard let testCase = self.testCase else {
            return .failure(.testCaseNotProvided)
        }
        guard let executionService = executionService else {
            switch configure(with: testCase) {
            case .success(let dependencies):
                setDependencies(dependencies)
                return .success(dependencies.executionService)
            case .failure(let error):
                return .failure(error)
            }
        }
        return .success(executionService)
    }
    
    /// Fails the test providing diagnostic informationon the invalid configuration.
    private func failOnConfigurationError(_ error: ConfigurationError) {
        let errorMessage: String
        let configFileName = "\(Constants.frameworkName).\(Constants.configurationType)"
        switch error {
        case .configurationNotProvided:
            errorMessage = "Unable to locate \(configFileName)."
        case .initialContextNotSpecified:
            errorMessage = """
            An initial context must be specified by providing a value for key 'initial-context'
            in your configuration file by by passing the initial context identifier when
            instantiating the test runner.
            """
        case .parsing(let parsingError):
            errorMessage = "Unable to parse \(configFileName) due to \(parsingError.localizedDescription)."
        case .testCaseNotProvided:
            errorMessage = """
            XTestCase instance required to execute tests. This should not occur typically but
            can be resolved by invoking setTestCase(_:) on the test runner and providing an
            XCTestCase instance.
            """
        }
        XCTFail(errorMessage)
    }
    
    /// Returns whether or not the test runner has been correctly configured.
    private func isConfigured() -> Bool {
        return executionService != nil
    }
    
    private func registerTestObserver() {
        XCTestObservationCenter.shared.addTestObserver(Skylark.testObserver)
    }
    
    private func setDependencies(_ dependencies: Dependencies) {
        self.contextManagementService = dependencies.contextManagementService
        self.executionService = dependencies.executionService
        self.stepResolutionService = dependencies.stepResolutionService
    }
    
    /// Reads number of times to retry failing scenarios.
    private func retryCountForFailingScenario() -> Int {
        for index in 1..<CommandLine.arguments.count
            where CommandLine.arguments[index] == "--retry" && index + 1 < CommandLine.arguments.count {
                if let retryCount = Int(CommandLine.arguments[index + 1]) {
                    return retryCount
                }
        }
        return 0
    }
    
}
