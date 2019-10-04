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
        case discovery
        case identifier = "id"
        case isTransient = "transient"
        case name
        case type
    }
    
    let discovery: Discovery
    let identifier: Identifier
    let isTransient: Bool
    let name: Name
    let type: ElementType
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        discovery = (try? container.decode(Discovery.self, forKey: .discovery)) ?? .none
        identifier = try container.decode(String.self, forKey: .identifier)
        isTransient = (try? container.decode(Bool.self, forKey: .isTransient)) ?? false
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(ElementType.self, forKey: .type)
    }
    
    init(identifier: Identifier, discovery: Discovery = .none, isTransient: Bool = false,
         name: Name, type: ElementType) {
        self.discovery = discovery
        self.identifier = identifier
        self.isTransient = isTransient
        self.name = name
        self.type = type
    }
}
