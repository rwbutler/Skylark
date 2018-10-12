//
//  FileExtensions.swift
//  Skylark
//
//  Created by Ross Butler on 9/27/18.
//

import Foundation

enum FileExtension: String {
    case feature
    case json
    case screen
}

extension FileExtension: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}
