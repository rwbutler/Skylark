//
//  Services.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation
import XCTest

// Factory for obtaining dependencies.
struct Services {
    
    // MARK: - Internal only
    private static var _contextManagement: ContextManagementService?
    
    // MARK: - Service vending.
    
    /// Configures the test framework using configuration files.
    static var configuration: ConfigurationService {
        return DefaultConfigurationService()
    }
    
    /// Manages state on behalf of the test framework.
    static func contextManagement(context: Context, model: SkylarkConfiguration) -> ContextManagementService {
        guard let contextManagement = _contextManagement else {
            let contextManagement = DefaultContextManagementService(context: context, model: model)
            _contextManagement = contextManagement
            return contextManagement
        }
        contextManagement.setContext(context)
        return contextManagement
    }

    /// Executes feature files comprising scenarios.
    static func executionService(contextManagement: ContextManagementService, stepResolver: StepResolutionService) -> ExecutionService {
        return ScenarioExecutionService(contextManagement: contextManagement, stepResolver: stepResolver)
    }
    
    /// Resolves resources including configuration files.
    static var resourceResolution: ResourceResolutionService {
        return DefaultResourceResolutionService()
    }
    
    /// Resolves written steps to executable actions.
    static func stepResolution(contextManagement: ContextManagementService, model: SkylarkConfiguration, testCase: XCTestCase) -> StepResolutionService {
        return DefaultStepResolutionService(contextManager: contextManagement, model: model, testCase: testCase)
    }
    
}
