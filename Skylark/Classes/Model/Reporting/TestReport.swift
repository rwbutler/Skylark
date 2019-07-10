//
//  SkylarkTestReport.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

enum TestReport {
    case feature(_ report: FeatureReport)
    case scenarios(_ reports: [ScenarioReport])
}
