//
//  ContextsWrapper.swift
//  Skylark
//
//  Created by Ross Butler on 8/14/19.
//

import Foundation

struct ContextsWrapper: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case contexts
    }
    
    let wrapped: Contexts
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.wrapped = try container.decode(Contexts.self, forKey: .contexts)
    }
    
}
