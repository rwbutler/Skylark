//
//  Scenario.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation

struct Scenario {
    var scenarioText: String?
    let given: Step
    let when: Step?
    let then: Step
}

extension Scenario: Evaluable {
    func evaluate() -> Bool {
        return given.evaluate()
            && (when?.evaluate() ?? true)
            && then.evaluate()
    }
}
