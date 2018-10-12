//
//  Step.swift
//  Skylark
//
//  Created by Ross Butler on 9/27/18.
//

import Foundation
import XCTest

enum StepDefinitions {
    case element(pageName: String, element: (key: String, value: String),
        query: XCUIElementQuery, stepDefinitions: [String: [String]])
    case keyboard(pageName: String, stepDefinitions: [String])
    case page(page: Page, stepDefinitions: [String])
}
