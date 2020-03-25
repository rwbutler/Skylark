//
//  ParsingService.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

protocol ParsingService {
    associatedtype T
    func parse(_ data: Data?) -> Result<T, ParsingError>
}
