//
//  ParsedFeature.swift
//  Skylark
//
//  Created by Ross Butler on 3/11/19.
//

import Foundation

struct ParsedFeature {
    /// Name of the feature.
    let name: String
    
    /// Scenarios belonging to the named feature.
    var scenarios: [ParsedScenario]
    
    let tagExpression: String?
    
    /// Tags assigned to the feature.
    let tags: [ParsedTag]?
    
    /// Description of the feature.
    let text: String?
    
    init(name: String, tags: [ParsedTag]?, scenarios: [ParsedScenario], tagExpression: String?, text: String?) {
        self.name = name
        self.scenarios = scenarios
        self.tagExpression = tagExpression
        self.tags = tags
        self.text = text
    }
}

extension ParsedFeature: CustomStringConvertible {
    var description: String {
        let tagExpression: String? = tags?.reduce("") { ( result, tag) in
            return result + "@\(tag) "
        }.trimmingCharacters(in: .whitespaces)
        return "\(tagExpression ?? "")\nFeature: \(name)\n\(text ?? "")"
    }
}
