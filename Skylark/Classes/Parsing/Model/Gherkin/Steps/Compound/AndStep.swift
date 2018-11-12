//
//  AndCondition.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation

public struct AndStep: CompoundStep {
    
    public let lhs: Step
    public let rhs: Step
    
    public func evaluate() -> Bool {
        let lhsResult = lhs.evaluate()
        let rhsResult = rhs.evaluate()
        return lhsResult && rhsResult
    }
}
