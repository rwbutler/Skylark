//
//  DefaultContextManagementService.swift
//  Skylark
//
//  Created by rRoss Butler on 3/3/19.
//

import Foundation

class DefaultContextManagementService: ContextManagementService {
    let initialState: Context
    let model: SkylarkConfiguration
    var stateRestoration: [Context] = []
    var currentState: Context {
        didSet {
            observers.forEach { $0.transitionedToContext(currentState) }
        }
    }
    
    var observers: [ContextTransitioned] = []
    
    init?(context: Screen.Identifier, model: SkylarkConfiguration) {
        guard let context = Context(screenIdentifier: context, model: model) else {
            return nil
        }
        self.model = model
        self.initialState = context
        self.currentState = context
        context.transitionDelegate = self
    }
    
    func actionPerformed(_ interaction: ElementInteraction) {
        currentState.actionPerformed(interaction)
    }
    
    func addObserver(_ observer: ContextTransitioned) {
        observers.append(observer)
    }
    
    func currentContext() -> Context {
        return currentState
    }
    
    func reset() {
        currentState = initialState
    }
    
    func setContext(_ contextId: Screen.Identifier) {
        guard contextId != currentState.screen.identifier,
            let context = Context(screenIdentifier: contextId, model: model) else {
            return
        }
        context.transitionDelegate = self
        currentState = context
    }
    
    deinit {
        observers.removeAll()
    }
}

extension DefaultContextManagementService: ContextTransitioning {
    func transitionContext(_ transition: ContextTransition) {
        switch transition.direction {
        case .forwards:
            // Instantiate a fresh context.
            guard let context = Context(screenIdentifier: transition.destination,
                                        model: model, parent: currentState) else {
                return
            }
            context.transitionDelegate = self
            stateRestoration.append(currentState)
            currentState = context
        case .backwards:
            if let parentContext = currentState.parent,
                parentContext.screen.identifier == transition.destination {
                let parentContextIndex = stateRestoration.lastIndex(where: {
                    $0.identifier == parentContext.identifier
                })
                if let removalIndex = parentContextIndex {
                    stateRestoration.remove(at: removalIndex)
                }
                currentState = parentContext
            }
        }
    }
}
