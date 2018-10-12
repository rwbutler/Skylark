//
//  NegatedCondition.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation

struct NegatedStep: Step {
    let expr: Step
    func evaluate() -> Bool {
        return !expr.evaluate()
    }
}
