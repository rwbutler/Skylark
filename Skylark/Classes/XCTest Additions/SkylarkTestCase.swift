//
//  SkylarkTestCase.swift
//  Argos
//
//  Created by Ross Butler on 6/20/19.
//  Copyright © 2019 Ross Butler. All rights reserved.
//

import Foundation
import XCTest

open class SkylarkTestCase: XCTestCase {
    
    public lazy var testRunner = Skylark.testRunner()
    
    override open func setUp() {
        testRunner.setTestCase(self)
    }
    
}
