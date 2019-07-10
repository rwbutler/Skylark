//
//  ConfigurationError.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

/// Error thrown in the event of test framework having been misconfigured.
enum ConfigurationError: Error {
    case configurationNotProvided
    case initialContextNotSpecified
    case parsing(_ parsingError: ParsingError)
    case testCaseNotProvided
}
