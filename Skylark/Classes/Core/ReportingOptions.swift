//
//  ReportingOptions.swift
//  Skylark
//
//  Created by Ross Butler on 6/25/19.
//  Copyright © 2019 Skylark. All rights reserved.
//

import Foundation

public struct ReportingOptions: OptionSet {
    public let rawValue: Int
    
    public static let always = ReportingOptions(rawValue: 1)
    public static let onlyOnFailure = ReportingOptions(rawValue: 2)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
}
