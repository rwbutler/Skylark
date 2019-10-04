//
//  TestObserver.swift
//  Skylark
//
//  Created by Ross Butler on 6/20/19.
//  Copyright © 2019 Ross Butler. All rights reserved.
//

import Foundation
import XCTest

class TestObserver: NSObject {
    
    // Instances to be notified of a new test case.
    private var observers: [Skylark] = []
    
    func addObserver(_ observer: Skylark) {
        observers.append(observer)
    }
    
}

extension TestObserver: XCTestObservation {
    
    func testCaseDidFinish(_ testCase: XCTestCase) {
    }
    
    func testCaseWillStart(_ testCase: XCTestCase) {
        observers.forEach { $0.setTestCase(testCase) }
    }
    
    func testBundleDidFinish(_ testBundle: Bundle) {
        Skylark.reportTestSummary()
    }
    
    func testBundleWillStart(_ testBundle: Bundle) {
    }
    
    func testSuiteDidFinish(_ testSuite: XCTestSuite) {
    }
    
    func testSuiteWillStart(_ testSuite: XCTestSuite) {
    }
    
}
