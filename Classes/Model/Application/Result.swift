//
//  NewModel.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation

enum Result<T, E: Error> {
    case success(T)
    case failure(E)
}
