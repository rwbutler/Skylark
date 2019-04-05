//
//  Parser.swift
//  Skylark
//
//  Created by Ross Butler on 9/27/18.
//

import Foundation

protocol Parser {
    associatedtype Model
    func parse(bundle: Bundle) -> [Model]?
}
