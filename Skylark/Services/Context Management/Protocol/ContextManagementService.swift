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
    func currentContext() -> ContextInstance
    func reset()
    func setContext(_ context: Context)
    func setContext(_ context: Context, preserveHistory: Bool)
    func setContext(identifier contextId: Context.Identifier)
    func setContext(identifier contextId: Context.Identifier, preserveHistory: Bool)
}
