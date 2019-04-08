//
//  Services.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation
import XCTest

struct Services {
    
    static var configuration: ConfigurationService {
        return DefaultConfigurationService()
    }
    
    /// Service for reporting on result of test executions.
    static var configurationResolution: ConfigurationResolutionService {
        return DefaultConfigurationResolutionService()
    }
    
    static var contextManagement: ContextManagementService?
    
    static func contextManagement(context: Screen.Identifier) -> ContextManagementService? {
        if let contextManagement = self.contextManagement {
            contextManagement.setContext(context)
            return contextManagement
        }
        switch configuration.configuration() {
        case .success(let model):
            contextManagement = DefaultContextManagementService(context: context, model: model)
        case .failure(let error):
            print(error)
        }
        return contextManagement
    }
    
    static func contextManagement(context: Screen.Identifier,
                                  model: SkylarkConfiguration) -> ContextManagementService? {
        if let contextManagement = contextManagement {
            contextManagement.setContext(context)
            return contextManagement
        }
        contextManagement = DefaultContextManagementService(context: context, model: model)
        return contextManagement
    }

    static func stepResolution(context: Screen.Identifier, model: SkylarkConfiguration,
                               testCase: XCTestCase) -> StepResolutionService? {
        guard let contextManagementService = contextManagement(context: context, model: model) else {
            return nil
        }
        return DefaultStepResolutionService(context: context, contextManager: contextManagementService,
                                            model: model, testCase: testCase)
    }
    
    /// Service for reporting on result of test executions.
    func reportingService(scenarioOutlineResults: [ScenarioOutlineResult]) -> ReportingService {
        return DefaultReportingService(scenarioOutlineResults: scenarioOutlineResults)
    }
    
    /// Service for reporting on result of test executions.
    func reportingService(scenarioReports: [ScenarioReport]) -> ReportingService {
        return DefaultReportingService(scenarioReports: scenarioReports)
    }
    
    /// Service for reporting on result of test executions.
    func reportingService(scenarioResults: [ScenarioResult]) -> ReportingService {
        return DefaultReportingService(scenarioResults: scenarioResults)
    }
}
