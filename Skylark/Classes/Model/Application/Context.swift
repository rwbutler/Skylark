//
//  Context.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

public struct Context: Codable {
    typealias Name = String
    public typealias Identifier = String
    
    enum CodingKeys: String, CodingKey {
        case name
        case elements
        case steps
    }
    let identifier: Identifier
    let name: Name
    let elements: [ElementType: [Element]]
    let steps: [ElementType: [ParameterisedStepType]]?
    
    public init(from decoder: Decoder) throws {
        
        guard let screenIdentifier = decoder.codingPath.last?.stringValue else {
            let container = try decoder.singleValueContainer()
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Cannot initialize Context without identifier."
            )
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = screenIdentifier
        name = try container.decode(Name.self, forKey: .name)
        
        let elements = try container.decode([Element].self, forKey: .elements)
        var elementMap: [ElementType: [Element]] = [:]
        elements.forEach { element in
            if var elementValues = elementMap[element.type] {
                elementValues.append(element)
                elementMap[element.type] = elementValues
            } else {
                elementMap[element.type] = [element]
            }
        }
        self.elements = elementMap
        
        guard let steps = try container.decodeIfPresent([String: [String: ParameterisedStepType]].self, forKey: .steps)
            else {
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
