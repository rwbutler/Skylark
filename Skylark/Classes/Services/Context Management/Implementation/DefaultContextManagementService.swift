//
//  DefaultContextManagementService.swift
//  Skylark
//
//  Created by rRoss Butler on 3/3/19.
//

import Foundation

class DefaultContextManagementService: ContextManagementService {
    let initialState: ContextInstance
    let model: SkylarkConfiguration
    var stateRestoration: [ContextInstance] = []
    var currentState: ContextInstance {
        didSet {
            observers.forEach { $0.transitionedToContext(currentState) }
        }
    }
    
    var observers: [ContextTransitioned] = []
    
    init(context: Context, model: SkylarkConfiguration) {
        let context = ContextInstance(context: context, model: model)
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
    
    func currentContext() -> ContextInstance {
        return currentState
    }
    
    func reset() {
        currentState = initialState
    }
    
    func setContext(_ context: Context) {
        setContext(context, preserveHistory: false)
    }
    
    func setContext(_ context: Context, preserveHistory: Bool = false) {
        // Check whether the current context is the same as the new context in which case, do nothing.
        guard context.identifier != currentState.context.identifier else {
            return
        }
        let contextInstance = ContextInstance(context: context, model: model)
        contextInstance.transitionDelegate = self
        if preserveHistory {
            stateRestoration.append(currentState)
        }
        currentState = contextInstance
    }
    
    func setContext(identifier contextId: Context.Identifier) {
        setContext(identifier: contextId, preserveHistory: false)
    }
    
    func setContext(identifier contextId: Context.Identifier, preserveHistory: Bool = false) {
        // Check whether the identifier represents a valid context.
        guard let contextModel = model.application.contexts[contextId] else {
            return
        }
        setContext(contextModel, preserveHistory: preserveHistory)
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
            let contextId = transition.destination
            guard let contextModel = model.application.contexts[contextId] else {
                return
            }
            let context = ContextInstance(context: contextModel, model: model, parent: currentState)
            context.transitionDelegate = self
            stateRestoration.append(currentState)
            currentState = context
        case .backwards:
            if let parentContext = currentState.parent,
                parentContext.context.identifier == transition.destination {
                let parentContextIndex = stateRestoration.lastIndex(where: {
                    $0.instanceId == parentContext.instanceId
                })
                if let removalIndex = parentContextIndex {
                    stateRestoration.remove(at: removalIndex)
                }
                currentState = parentContext
            }
        }
    }
}
