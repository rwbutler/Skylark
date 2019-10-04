//
//  SkylarkApplication.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

struct Application: Codable {
    
    // MARK: - Type definitions
    enum CodingKeys: String, CodingKey {
        case initialContext = "initial-context"
        case map
        case contexts
        case steps
    }
    
    // MARK: - State
    let initialContext: Context.Identifier?
    let map: ApplicationMap
    let contexts: [Context.Identifier: Context]
    let steps: [ElementType: [ParameterisedStepType]]
    
    // MARK: - Life cycle
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.initialContext = try container.decodeIfPresent(Context.Identifier.self, forKey: .initialContext)
        self.map = try container.decode(ApplicationMap.self, forKey: .map)
        self.contexts = try container.decode([Context.Identifier: Context].self, forKey: .contexts)
        let steps = try container.decode([String: [String: ParameterisedStepType]].self, forKey: .steps)
        let intermediateDictionary: [String: [ParameterisedStepType]] = steps.mapValues { dictionary in
            return dictionary.map { $0.value }
        }
        // Convert to tuples which can be used to instantiate a dictionary.
        let stepTuples: [(ElementType, [ParameterisedStepType])] = intermediateDictionary.compactMap {
            guard let elementType = ElementType(rawValue: $0.key) else { return nil }
            return (elementType, $0.value)
        }
        self.steps = Dictionary(stepTuples)
    }
    
    init(contexts: Contexts, map: ApplicationMap?, steps: Steps?) {
        self.contexts = contexts
        self.initialContext = nil
        self.map = map ?? ApplicationMap(map: [:])
        self.steps = steps ?? [:]
    }
    
}
