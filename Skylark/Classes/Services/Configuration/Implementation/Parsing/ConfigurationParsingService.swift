//
//  ConfigurationParsingService.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

struct ConfigurationParsingService: ParsingService {

    typealias T = SkylarkConfiguration
    
    func parse(_ data: Data?) -> Result<T, ParsingError> {
        
        // Check that data was supplied for parsing.
        guard let data = data, !data.isEmpty else { return .failure(.emptyPayload) }
        
        // Attempt to parse data using Codable and JSONDecoder.
        let decoder = JSONDecoder()
        do {
            let configWrapper = try decoder.decode(SkylarkConfigurationWrapper.self, from: data) //else {
            let configuration = configWrapper.skylark
            return .success(configuration)
        } catch let error {
            return .failure(.unexpectedFormat(error))
        }
    }
}
