//
//  ScenarioFailure.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

enum ScenarioFailure: Error {
    case missingGivenClause
    case missingThenClause
    case noMatchingStep(_ step: String)
    case stepFailure(_ step: String)
}
