//
//  ReportingService.swift
//  Skylark
//
//  Created by Ross Butler on 4/5/19.
//

import Foundation

protocol ReportingService {
    init(scenarioOutlineResults: [ScenarioOutlineResult])
    init(scenarioReports: [ScenarioReport])
    init(scenarioResults: [ScenarioResult])
    func summary() -> String
}
