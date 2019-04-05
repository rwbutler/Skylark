//
//  ContextManagementService.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

protocol ContextManagementService {
    func actionPerformed(_ interaction: ElementInteraction)
    func addObserver(_ observer: ContextTransitioned)
    func currentContext() -> Context
    func reset()
    func setContext(_ contextId: Screen.Identifier)
}
