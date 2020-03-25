//
//  StepResolutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation
import XCTest

protocol StepResolutionService {
    func register(step: String, evaluable: Evaluable)
    func register(step: String, evaluable: Evaluable, screen: Context.Identifier?)
    func resolve(step: String) -> Evaluable?
    func updateTestCase(_ testCase: XCTestCase)
    func unregisterSteps()
    func unregisterSteps(context: Context.Identifier)
}
