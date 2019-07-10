//
//  SetUp.swift
//  Argos
//
//  Created by Ross Butler on 6/10/19.
//

import Foundation
import XCTest

public typealias TearDown = SetUp

public struct SetUp {
    
    let closure: () -> Void
    let trigger: Trigger
    
    init(_ closure: @escaping () -> Void, trigger: Trigger) {
        self.closure = closure
        self.trigger = trigger
    }
    
    func execute() {
        guard XCUIApplication().wait(for: .runningForeground, timeout: 10.0) else {
            XCTFail("Failure whilst waiting for application to run in foreground.")
            return
        }
        closure()
    }
    
}
