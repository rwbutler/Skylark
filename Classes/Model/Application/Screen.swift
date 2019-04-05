//
//  Screen.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

struct Screen: Codable {
    typealias Name = String
    typealias Identifier = String
    
    enum CodingKeys: String, CodingKey {
        case name
        case elements
        case steps
    }
    let identifier: Identifier
    let name: Name
    let elements: [ElementType: [Element]]
    let steps: [ElementType: [ParameterisedStepType]]?
    
    init(from decoder: Decoder) throws {
        
        guard let screenIdentifier = decoder.codingPath.last?.stringValue else {
            let container = try decoder.singleValueContainer()
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Cannot initialize SkylarkScreen without identifier."
            )
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = screenIdentifier
        name = try container.decode(Name.self, forKey: .name)
        let elementMap = try container.decode([String: [String: String]].self, forKey: .elements)
        let elementTuples: [(ElementType, [Element])] = elementMap.compactMap { element in
            guard let elementType = ElementType(rawValue: element.key) else { return nil }
            let elements = element.value.map { Element(identifier: $0.value, name: $0.key, type: elementType) }
            let elementTypeTuple: (ElementType, [Element]) = (elementType, elements)
            return elementTypeTuple
        }
        elements = Dictionary(elementTuples)
        guard let steps = try container.decodeIfPresent([String: [String: ParameterisedStepType]].self, forKey: .steps) else {
            self.steps = nil
            return
        }
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
