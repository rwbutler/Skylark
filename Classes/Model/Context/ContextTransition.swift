//
//  SkylarkApplicationMapDestination.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

struct ContextTransition: Codable {
    
    enum CodingKeys: String, CodingKey {
        case actions
        case direction
        case destination
    }
    
    let direction: ContextTransitionDirection
    let actions: [ElementInteraction]
    let destination: Screen.Identifier
    
    init(destination: Screen.Identifier, actions: [ElementInteraction],
         direction: ContextTransitionDirection = .forwards) {
        self.actions = actions
        self.destination = destination
        self.direction = direction
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        direction = try container.decodeIfPresent(ContextTransitionDirection.self, forKey: .direction) ?? .forwards
        destination = try container.decode(Screen.Identifier.self, forKey: .destination)
        actions = try container.decode([ElementInteraction].self, forKey: .actions)
    }
    
    func unfulfilledTransition() -> ContextTransition {
        return ContextTransition(destination: self.destination, actions: [], direction: direction)
    }
}
