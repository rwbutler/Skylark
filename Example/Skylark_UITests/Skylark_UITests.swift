//
//  Skylark_UITests.swift
//  Skylark_UITests
//
//  Created by Ross Butler on 10/12/18.
//  Copyright © 2018 Ross Butler. All rights reserved.
//

import XCTest
import Skylark

class Tests: XCTestCase {
    
    /// Obtain an instance of the test runner
    lazy var testRunner = Skylark.testRunner(testCase: self, context: "Home")
    
    func testFromFeatureFile() {
        // Execute scenarios from feature file
        //testRunner.test(featureFile: "Main")
    }
    
}
