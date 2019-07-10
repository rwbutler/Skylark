//
//  ScenarioFailure.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

enum ScenarioFailure: Error {
    case noMatchingStep(_ step: String)
    case stepFailure(_ step: String)
}

extension ScenarioFailure: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .noMatchingStep(let step):
            return "Didn't know what to do with '\(step)' 🤷🏻‍♂️."
        case .stepFailure(let step):
            return "Assertion failure for '\(step)' ❌."
        }
    }
    
}
