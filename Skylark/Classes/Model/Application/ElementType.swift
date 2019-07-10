//
//  ElementTypes.swift
//  Skylark
//
//  Created by Ross Butler on 9/25/18.
//

import Foundation
import XCTest

enum ElementType: String, Codable, CaseIterable {
    
    case buttons
    case cells
    case elements
    case keyboards
    case screen = "pages"
    case tabs
    case tabBars = "tab-bars"
    case text
    case textFields = "text-fields"
    case navigationBars = "navigation-bars"
    case webViews = "web-views"
    
    var xcuiElement: XCUIElementQuery? {
        switch self {
        case .screen:
            return nil
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
            return XCUIApplication().buttons
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

extension ElementType: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}

/*
 case activityIndicator
 case alert
 case any
 case application
 case browser
 case button
 case cell
 case checkBox
 case collectionView
 case colorWell
 case comboBox
 case datePicker
 case decrementArrow
 case dialog
 case disclosureTriangle
 case dockItem
 case drawer
 case grid
 case group
 case handle
 case helpTag
 case icon
 case image
 case incrementArrow
 case key
 case keyboard
 case layoutArea
 case layoutItem
 case levelIndicator
 case link
 case map
 case matte
 case menu
 case menuBar
 case menuBarItem
 case menuButton
 case menuItem
 case navigationBar
 case other
 case outline
 case outlineRow
 case pageIndicator
 case picker
 case pickerWheel
 case popUpButton
 case popover
 case progressIndicator
 case radioButton
 case radioGroup
 case ratingIndicator
 case relevanceIndicator
 case ruler
 case rulerMarker
 case scrollBar
 case scrollView
 case searchField
 case secureTextField
 case segmentedControl
 case sheet
 case slider
 case splitGroup
 case splitter
 case staticText
 case statusBar
 case statusItem
 case stepper
 case `switch`
 case tab
 case tabBar
 case tabGroup
 case table
 case tableColumn
 case tableRow
 case textField
 case textView
 case timeline
 case toggle
 case toolbar
 case toolbarButton
 case valueIndicator
 case webView
 case window
 case touchBar
 */
