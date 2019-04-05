//
//  ParsedScenario.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

struct ParsedScenario {
    
    /// Scenario name
    let name: String
    
    let tagExpression: String?
    
    /// Tags for conditional execution of scenarios
    let tags: [ParsedTag]?
    
    /// Steps definitions i.e. given, when, then
    let text: String
    
    /// Type of scenario e.g. outline
    let type: ParsedScenarioType
    
    init(name: String, tagExpression: String?, tags: [ParsedTag]?, text: String, type: ParsedScenarioType) {
        self.name = name
        self.tagExpression = tagExpression
        self.tags = tags
        self.text = text
        self.type = type
    }
}
