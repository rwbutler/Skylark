//
//  SkylarkConfiguration.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

struct SkylarkConfiguration: Codable {
    
    enum CodingKeys: String, CodingKey {
        case application
    }
    
    let application: Application
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.application = try container.decode(Application.self, forKey: .application)
    }
}
