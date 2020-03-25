//
//  MapWrapper.swift
//  Skylark
//
//  Created by Ross Butler on 8/14/19.
//

import Foundation

struct MapWrapper: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case map
    }
    
    let wrapped: ApplicationMap
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.wrapped = try container.decode(ApplicationMap.self, forKey: .map)
    }
    
}
