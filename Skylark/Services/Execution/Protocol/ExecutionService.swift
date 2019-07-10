//
//  ExecutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/12/19.
//

import Foundation

protocol ExecutionService {
    var launchArgs: [LaunchArguments] { get set }
    var setUps: [SetUp] { get set }
    var tearDowns: [TearDown] { get set }
    func execute(feature: Feature, retryCount: Int) -> TestReport
    func execute(scenarios: [Scenario], retryCount: Int) -> TestReport
}
