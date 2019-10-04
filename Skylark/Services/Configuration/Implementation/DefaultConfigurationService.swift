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
        let contextsFileName = "\(Skylark.Constants.frameworkName)-Contexts"
        let mappingsFileName = "\(Skylark.Constants.frameworkName)-Map"
        let stepsFileName = "\(Skylark.Constants.frameworkName)-Steps"
        let fileExtension = Skylark.Constants.configurationType.description
        let configURL = resourceResolver.url(forResource: configFileName, withExtension: fileExtension)
        let contextsURL = resourceResolver.url(forResource: contextsFileName, withExtension: fileExtension)
        let mappingsURL = resourceResolver.url(forResource: mappingsFileName, withExtension: fileExtension)
        let stepsURL = resourceResolver.url(forResource: stepsFileName, withExtension: fileExtension)
        
        let decoder = JSONDecoder()
        if let configURL = configURL, let configData = try? Data(contentsOf: configURL) {
            do {
                let configWrapper = try decoder.decode(SkylarkConfigurationWrapper.self, from: configData)
                return .success(configWrapper.skylark)
            } catch let error {
                return .failure(.parsing(.unexpectedFormat(error)))
            }
        } else if let contextsURL = contextsURL, let contextsData = try? Data(contentsOf: contextsURL) {
            do {
                let contexts = try decoder.decode(ContextsWrapper.self, from: contextsData)
                let map: MapWrapper?
                if let mappingsURL = mappingsURL, let mapData = try? Data(contentsOf: mappingsURL) {
                    map = try decoder.decode(MapWrapper.self, from: mapData)
                } else {
                    map = nil
                }
                let steps: StepsWrapper?
                if let stepsURL = stepsURL, let stepsData = try? Data(contentsOf: stepsURL) {
                    steps = try decoder.decode(StepsWrapper.self, from: stepsData)
                } else {
                    steps = nil
                }
                let app = Application(contexts: contexts.wrapped, map: map?.wrapped, steps: steps?.wrapped)
                return .success(SkylarkConfiguration(app: app))
            } catch let error {
                return .failure(.parsing(.unexpectedFormat(error)))
            }
        } else { // As a minimum we require a complete config or at least context definitions.
            // TODO: Prefer logging over printing.
            let configNameWithExt = "\(configFileName).\(fileExtension)"
            let contextsNameWithExt = "\(contextsFileName).\(fileExtension)"
            debugPrint("Unable to locate either \(configNameWithExt) or \(contextsNameWithExt).")
            return .failure(.configurationNotProvided)
        }
    }
    
}
