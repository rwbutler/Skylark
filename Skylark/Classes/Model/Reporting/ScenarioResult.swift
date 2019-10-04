//
//  ScenarioResult.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

enum ScenarioResult {
    case notExecuted(_ reason: NonExecutionReason)
    case success
    case flaky(_ results: [ScenarioResult])
    case failure(_ failure: ScenarioFailure)
    
    func isSuccess() -> Bool {
        return self == .success
    }
    
    func isFlaky() -> Bool {
        return self == .flaky([])
    }
    
    func isFailure() -> Bool {
        return self == .failure(.stepFailure(""))
    }
    
    func isNotExecuted() -> Bool {
        return self == .notExecuted(.unrecognizedTagExpression)
    }
    
    var boolValue: Bool {
        switch self {
        case .notExecuted(.generic), .notExecuted(.tagMismatch), .success, .flaky:
            return true
        case .notExecuted(.unrecognizedTagExpression), .failure:
            return false
        }
    }
}

extension ScenarioResult: Equatable {
    static func == (lhs: ScenarioResult, rhs: ScenarioResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success), (.flaky, .flaky), (.failure, .failure), (.notExecuted, .notExecuted):
            return true
        default:
            return false
        }
    }
}

extension ScenarioResult: CustomStringConvertible {
    var description: String {
        switch self {
        case .notExecuted:
            return "Not executed 🙅🏻‍♂️"
        case .success:
            return "Scenario passed ✅"
        case .flaky:
            return "Scenario flaky ⚠️"
        case .failure:
            return "Scenario failed ❌"
        }
    }
}
