//
//  OrCondition.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation

struct OrStep: CompoundStep {
    let lhs: Step
    let rhs: Step
    func evaluate() -> Bool {
        let lhsResult = lhs.evaluate()
        let rhsResult = rhs.evaluate()
        return lhsResult || rhsResult
    }
}
