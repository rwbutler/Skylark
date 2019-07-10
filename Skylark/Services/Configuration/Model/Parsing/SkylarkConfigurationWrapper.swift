//
//  SkylarkConfigurationWrapper.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

struct SkylarkConfigurationWrapper: Codable {
    
    enum CodingKeys: String, CodingKey {
        case skylark
    }
    
    let skylark: SkylarkConfiguration
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.skylark = try container.decode(SkylarkConfiguration.self, forKey: .skylark)
    }
}
