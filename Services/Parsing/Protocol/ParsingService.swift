//
//  ParsingService.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

protocol ParsingService {
    // swiftlint:disable:next type_name
    associatedtype T
    func parse(_ data: Data?) -> Result<T, ParsingError>
}
