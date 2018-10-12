//
//  SupportedElementTypes.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation
import XCTest

enum SupportedElementType: String, CaseIterable {
    case buttons
    case cells
    case elements
    case keyboards
    case tabs
    case tabBars = "tab-bars"
    case text
    case textFields = "text-fields"
    case navigationBars = "navigation-bars"
    case webViews = "web-views"
    
    var xcuiElement: XCUIElementQuery {
        switch self {
        case .buttons:
            return XCUIApplication().buttons
        case .cells:
            return XCUIApplication().cells
        case .elements:
            return XCUIApplication().otherElements
        case .keyboards:
            return XCUIApplication().keyboards
        case .navigationBars:
            return XCUIApplication().navigationBars
        case .tabs:
            return XCUIApplication().tabs
        case .tabBars:
            return XCUIApplication().tabBars.buttons
        case .text:
            return XCUIApplication().staticTexts
        case .textFields:
            return XCUIApplication().textFields
        case .webViews:
            return XCUIApplication().webViews
        }
    }
}

extension SupportedElementType: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}
