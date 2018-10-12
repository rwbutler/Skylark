//
//  CompoundStep.swift
//  Skylark
//
//  Created by Ross Butler on 9/27/18.
//

import Foundation

protocol CompoundStep: Step {
    var lhs: Step { get }
    var rhs: Step { get }
}
