//
//  Conjunction.swift
//  Argos
//
//  Created by Ross Butler on 6/10/19.
//  Copyright © 2019 Argos. All rights reserved.
//

import Foundation

enum BinaryConjunction: String, CaseIterable {
    case and
    case or
    case but
    
    func join(lhs: String, rhs: String) -> String {
        return "\(lhs) \(rawValue) \(rhs)"
    }
    
    /// Returns (lhs, rhs) if the original string can be be split using the current conjunction, otherwise `nil`.
    func split(_ string: String) -> (String, String)? {
        let separator = " \(rawValue) "
        var components = string.components(separatedBy: separator)
        guard components.count >= 2 else {
            return nil
        }
        let lhs = components[0]
        components.removeFirst()
        let rhs = components.joined(separator: separator)
        return (lhs, rhs)
    }
    
    func step(lhs: Step, rhs: Step) -> Step? {
        switch self {
        case .and, .but:
            return AndStep(lhs: lhs, rhs: rhs)
        case .or:
            return OrStep(lhs: lhs, rhs: rhs)
        }
    }
    
}
