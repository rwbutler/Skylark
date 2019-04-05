//
//  Element.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

struct Element: Codable {
    
    typealias Identifier = String
    typealias Name = String
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case name
        case type
    }
    
    let identifier: Identifier
    let name: Name
    let type: ElementType
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let dictionary = try container.decode([Element.Name: Element.Identifier].self).first,
            let elementTypeStr = container.codingPath.last?.stringValue,
            let elementType = ElementType(rawValue: elementTypeStr) else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Cannot initialize SkylarkElement from empty dictionary."
                )
        }
        identifier = dictionary.value
        name = dictionary.key
        type = elementType
    }
    
    init(identifier: Identifier, name: Name, type: ElementType) {
        self.identifier = identifier
        self.name = name
        self.type = type
    }
}
