//
//  Scenario.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

struct Scenario {
    
    /// Scenario name
    let name: String
    
    let tagExpression: String?
    
    /// Tags for conditional execution of scenarios
    let tags: [Tag]?
    
    /// Steps definitions i.e. given, when, then
    let text: String
    
    /// Type of scenario e.g. outline
    let type: ScenarioType
    
    init(name: String, tagExpression: String?, tags: [Tag]?, text: String, type: ScenarioType) {
        self.name = name
        self.tagExpression = tagExpression
        self.tags = tags
        self.text = text
        self.type = type
    }
    
}
