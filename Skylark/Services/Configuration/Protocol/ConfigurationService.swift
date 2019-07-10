//
//  ConfigurationService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

protocol ConfigurationService {
    func configuration() -> Result<SkylarkConfiguration, ConfigurationError>
}
