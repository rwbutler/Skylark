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
            let emojiString = Skylark.emojiInOutput ? "🤷🏻‍♂️" : ""
            return "Didn't know what to do with '\(step)' \(emojiString)."
        case .stepFailure(let step):
            let emojiString = Skylark.emojiInOutput ? "❌" : ""
            let trimmedStep = step.trimmingCharacters(in: .whitespacesAndNewlines)
            return "Assertion failure for '\(step)' \(emojiString)."
        }
    }
    
}
