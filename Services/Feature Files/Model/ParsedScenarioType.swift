//
//  ParsedScenarioType.swift
//  Skylark
//
//  Created by Ross Butler on 3/12/19.
//

import Foundation

enum ParsedScenarioType: String, CaseIterable {
    case scenario = "Scenario"
    case scenarioOutline = "Scenario Outline"
    case scenarioPermutations = "Scenario Permutations"
}
