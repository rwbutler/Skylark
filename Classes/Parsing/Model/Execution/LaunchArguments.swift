//
//  LaunchArguments.swift
//  Skylark
//
//  Created by Ross Butler on 10/15/18.
//

import Foundation

public enum LaunchArguments {
    case custom(String)
    case resetBeforeEachScenario
}

extension LaunchArguments: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "reset-before-each-scenario":
            self = .resetBeforeEachScenario
        default:
            self = .custom(rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .custom(let customStr):
            return customStr
        case .resetBeforeEachScenario:
            return "reset-before-each-scenario"
        }
    }
}
