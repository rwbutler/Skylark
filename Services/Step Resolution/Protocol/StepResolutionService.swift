//
//  StepResolutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

protocol StepResolutionService {
    func register(step: String, evaluable: Evaluable)
    func register(step: String, evaluable: Evaluable, screen: Screen.Identifier?)
    func resolve(step: String) -> Evaluable?
}
