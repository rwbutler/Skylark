//
//  LaunchArguments.swift
//  Skylark
//
//  Created by Ross Butler on 10/15/18.
//

import Foundation

public enum LaunchArguments {
    case caseSensitiveMatching
    case custom(String)
    case resetEachScenario
}

extension LaunchArguments: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "case-insensitive-matching":
            self = .caseSensitiveMatching
        case "reset-before-each-scenario":
            self = .resetEachScenario
        default:
            self = .custom(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .caseSensitiveMatching:
            return "case-insensitive-matching"
        case .custom(let customStr):
            return customStr
        case .resetEachScenario:
            return "reset-before-each-scenario"
        }
    }
}
