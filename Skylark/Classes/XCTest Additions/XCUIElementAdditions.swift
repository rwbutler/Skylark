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
    
    public func swipeUp(count: Int = 5) {
        var counter = 0
        while counter <= count {
            guard !exists else { return }
            XCUIApplication().swipeUp()
            counter += 1
        }
    }
    
    public func swipeDown(count: Int = 5) {
        var counter = 0
        while counter <= count {
            guard !exists else { return }
            XCUIApplication().swipeDown()
            counter += 1
        }
    }
    
    public func scrollToElement(numberOfSwipes: Int = 5, timeout: Double = 10) {
        var counter = 0
        while waitForExistence(timeout: timeout) && !isHittable && counter <= numberOfSwipes {
            XCUIApplication().swipeUp()
            counter += 1
        }
        counter = 0
        while waitForExistence(timeout: timeout) && !isHittable && counter <= numberOfSwipes {
            XCUIApplication().swipeDown()
            counter += 1
        }
    }
    
    public func swipeUpAndWait(count: Int = 5, timeout: Double = 10.0) {
        guard !exists else { return }
        var counter = 0
        while waitForExistence(timeout: timeout) && !isHittable && counter <= count {
            XCUIApplication().swipeUp()
            guard !exists else { return }
            counter += 1
        }
    }
    
    public func swipeDownAndWait(count: Int = 5, timeout: Double = 10.0) {
        guard !exists else { return }
        var counter = 0
        while waitForExistence(timeout: timeout) && !isHittable && counter <= count {
            XCUIApplication().swipeDown()
            guard !exists else { return }
            counter += 1
        }
    }
    
}
