//
//  SimpleCondition.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation

struct SimpleStep: Step {
    let expr: () -> Bool
    init(_ expr: @escaping () -> Bool) {
        self.expr = expr
    }

    func evaluate() -> Bool {
        return expr()
    }
}
