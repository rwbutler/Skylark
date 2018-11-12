//
//  SimpleCondition.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation

public struct SimpleStep: Step {
    
    let expr: () -> Bool
    
    public init(_ expr: @escaping () -> Bool) {
        self.expr = expr
    }

    public func evaluate() -> Bool {
        return expr()
    }
    
}
