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
    
    init(app: Application) {
        self.application = app
    }
    
    /// Resolves a context identifier to a `Context` model object.
    func context(for id: Context.Identifier?) -> Context? {
        let contextKeys = application.contexts.keys
        guard let id = id, let contextKey = contextKeys.first(where: { id.lowercased() == $0.lowercased() }) else {
            return nil
        }
        return application.contexts[contextKey]
    }
}
