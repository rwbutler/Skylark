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
        case initialScreen = "initial-screen"
        case map
        case screens
        case steps
    }
    
    // MARK: - State
    let initialScreen: Screen.Identifier?
    let map: ApplicationMap
    let screens: [Screen.Identifier: Screen]
    let steps: [ElementType: [ParameterisedStepType]]
    
    // MARK: - Life cycle
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.initialScreen = try container.decodeIfPresent(Screen.Identifier.self, forKey: .initialScreen)
        self.map = try container.decode(ApplicationMap.self, forKey: .map)
        self.screens = try container.decode([Screen.Identifier: Screen].self, forKey: .screens)
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
}
