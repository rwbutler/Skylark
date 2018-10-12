//
//  XCUIElementAdditions.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import XCTest

extension XCUIElement {
    func scrollToElement() {
        var counter = 0
        while waitForExistence(timeout: 10) && !isHittable && counter <= 10 {
            XCUIApplication().swipeUp()
            counter += 1
        }
    }
}
