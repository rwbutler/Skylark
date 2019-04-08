//
//  SkylarkConfigurationService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

public class DefaultConfigurationService: ConfigurationService {
    
    let parser = ConfigurationParsingService()
    let resourceResolver = DefaultConfigurationResolutionService()
    
    func configuration() -> Result<SkylarkConfiguration, ConfigurationError> {
        guard let configurationURL = resourceResolver.url(forResource: "Skylark", withExtension: "json") else {
            print("Unable to location Skylark.json")
            return .failure(.configurationMissing)
        }
        let configuration = parser.parse(try? Data(contentsOf: configurationURL))
        switch configuration {
        case .success(let configuration):
            return .success(configuration)
        case .failure(let error):
            return .failure(.parsing(error))
        }
    }
}
