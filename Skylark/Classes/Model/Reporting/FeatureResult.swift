//
//  FeatureFileResult.swift
//  Skylark
//
//  Created by Ross Butler on 3/14/19.
//

import Foundation

enum FeatureResult {
    case success
    case failure(_ reasons: [ScenarioFailure])
    case notExecuted(_ reason: NonExecutionReason)
    
    var boolValue: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        case .notExecuted(.tagMismatch):
            return true
        case .notExecuted(.unrecognizedTagExpression):
            return false
        case .notExecuted(.generic):
            return true
        }
    }
}

enum NonExecutionReason {
    case generic
    case tagMismatch(tagExpr: String, testRunnerTagExpr: String)
    case unrecognizedTagExpression
}
