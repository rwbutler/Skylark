//
//  ApplicationMap.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

struct ApplicationMap: Codable {
    let map: [Context.Identifier: [ContextTransition]]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        map = try container.decode([Context.Identifier: [ContextTransition]].self)
    }
}
