//
//  ElementInteraction.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

struct ElementInteraction: Codable {
    
    typealias InteractionType = ElementInteractionType
    
    let action: InteractionType
    let element: Element.Identifier
    
    init(action: InteractionType, element: Element.Identifier) {
        self.action = action
        self.element = element
    }
    
}

extension ElementInteraction: Equatable {
    public static func == (lhs: ElementInteraction, rhs: ElementInteraction) -> Bool {
        return lhs.element == rhs.element && lhs.action.rawValue == rhs.action.rawValue
    }
}
