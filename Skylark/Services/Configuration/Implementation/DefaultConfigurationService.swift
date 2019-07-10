//
//  SkylarkConfigurationService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

public class DefaultConfigurationService: ConfigurationService {
    
    let parser = ConfigurationParsingService()
    let resourceResolver = DefaultResourceResolutionService()
    
    func configuration() -> Result<SkylarkConfiguration, ConfigurationError> {
        let configFileName = Skylark.Constants.frameworkName
        let configFileExtension = Skylark.Constants.configurationType.description
        guard let configurationURL = resourceResolver.url(forResource: configFileName, withExtension: configFileExtension) else {
            debugPrint("Unable to locate \(configFileName).\(configFileExtension).") // TODO: Prefer logging over printing.
            return .failure(.configurationNotProvided)
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
