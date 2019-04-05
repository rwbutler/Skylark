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
}

extension ScenarioResult: Equatable {
    static func == (lhs: ScenarioResult, rhs: ScenarioResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success), (.flaky, .flaky), (.failure, .failure):
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
