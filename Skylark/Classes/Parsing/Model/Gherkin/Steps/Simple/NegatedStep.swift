//
//  NegatedCondition.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation

public struct NegatedStep: Step {
    
    let expr: Evaluable
    
    public func evaluate() -> Bool {
        return !expr.evaluate()
    }
    
}
