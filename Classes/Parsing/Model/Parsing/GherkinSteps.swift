//
//  GherkinSteps.swift
//  Skylark
//
//  Created by Ross Butler on 9/26/18.
//

import Foundation

struct GherkinSteps: OptionSet {
    let rawValue: Int
    static let given = GherkinSteps(rawValue: 1 << 0)
    static let when = GherkinSteps(rawValue: 1 << 1)
    static let then = GherkinSteps(rawValue: 1 << 2)
    static let and = GherkinSteps(rawValue: 1 << 3)
    static let or = GherkinSteps(rawValue: 1 << 4)
    static let but = GherkinSteps(rawValue: 1 << 5)
}

extension GherkinSteps: CustomStringConvertible {
    var description: String {
        switch self {
        case .given:
            return "given"
        case .when:
            return "when"
        case .then:
            return "then"
        case .and:
            return "and"
        case .or:
            return "or"
        case .but:
            return "but"
        default:
            return ""
        }
    }
}
