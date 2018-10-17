//
//  XCUIElementAdditions.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import XCTest

extension XCUIElement {
    public func scrollToCell(numberOfSwipes: Int = 5, timeout: Int = 10) {
        var counter = 0
        while counter <= numberOfSwipes {
            guard !exists else { return }
            XCUIApplication().swipeUp()
            counter += 1
        }
        counter = 0
        while counter <= numberOfSwipes {
            guard !exists else { return }
            XCUIApplication().swipeDown()
            counter += 1
        }
    }
    
    public func scrollToElement(numberOfSwipes: Int = 5, timeout: Int = 10) {
        var counter = 0
        while waitForExistence(timeout: 11) && !isHittable && counter <= numberOfSwipes {
            XCUIApplication().swipeUp()
            counter += 1
        }
        counter = 0
        while waitForExistence(timeout: 12) && !isHittable && counter <= numberOfSwipes {
            XCUIApplication().swipeDown()
            counter += 1
        }
    }
}
