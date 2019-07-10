//
//  ParameterisedStepType.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

enum ParameterisedStepType: Codable, Hashable {
    
    case interaction([String: [String]])
    case existence([String])
    case registered(String)
    
    enum CodingKeys: String, CodingKey {
        case existence
        case action = "interaction"
        case manual
    }
    
    init(from decoder: Decoder) throws {
        guard let codingKey = decoder.codingPath.last, let keys = CodingKeys(rawValue: codingKey.stringValue) else {
            let container = try decoder.singleValueContainer()
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Cannot initialize ParameterisedStepType with invalid CodingKey."
            )
        }
        let container = try decoder.singleValueContainer()
        switch keys {
        case .existence:
            let leftValue =  try container.decode([String].self)
            self = .existence(leftValue)
        case .action:
            let rightValue =  try container.decode([String: [String]].self)
            self = .interaction(rightValue)
        case .manual:
            let leftValue =  try container.decode(String.self)
            self = .registered(leftValue)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .existence(let value):
            try container.encode(value, forKey: .existence)
        case .interaction(let value):
            try container.encode(value, forKey: .action)
        case .registered(let value):
            try container.encode(value, forKey: .manual)
        }
    }
    
}
