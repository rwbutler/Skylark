//
//  StepsWrapper.swift
//  Skylark
//
//  Created by Ross Butler on 8/14/19.
//

import Foundation

struct StepsWrapper: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case steps
    }
    
    let wrapped: Steps

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let steps = try container.decode([String: [String: ParameterisedStepType]].self, forKey: .steps)
        let intermediateDictionary: [String: [ParameterisedStepType]] = steps.mapValues { dictionary in
            return dictionary.map { $0.value }
        }
        // Convert to tuples which can be used to instantiate a dictionary.
        let stepTuples: [(ElementType, [ParameterisedStepType])] = intermediateDictionary.compactMap {
            guard let elementType = ElementType(rawValue: $0.key) else { return nil }
            return (elementType, $0.value)
        }
        self.wrapped = Dictionary(stepTuples)
    }
    
}
