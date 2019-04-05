//
//  ConfigurationError.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

enum ConfigurationError: Error {
    case parsing(_ parsingError: ParsingError)
    case configurationMissing
}
