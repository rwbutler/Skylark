//
//  ParsingError.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

public enum ParsingError: Error {
    case emptyPayload
    case invalidRegEx
    case unexpectedFormat(_ error: Error?)
}
