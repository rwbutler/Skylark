//
//  Trigger.swift
//  Skylark
//
//  Created by Ross Butler on 6/27/19.
//  Copyright © 2019 Ross Butler. All rights reserved.
//

import Foundation

public enum Trigger: Equatable {
    case eachFeature
    case eachScenario
    case eachStep
    case scenario(named: String)
    case step(scenario: String, step: String)
    case simulatorReset
}
