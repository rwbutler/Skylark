//
//  ContextInstance.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

public class ContextInstance {
    let instanceId: UUID // For equality checks only.
    /// Reflects actions which must be completed to move to the next destination
    let destinationsMap: [Context.Identifier: ContextTransition]
    /// Reflects actions which have actually been performed so far towards a destination.
    var state: [Context.Identifier: ContextTransition]
    let context: Context
    let parent: ContextInstance?
    weak var transitionDelegate: ContextTransitioning?
    
    init(context: Context, model: SkylarkConfiguration, parent: ContextInstance? = nil) {
        self.instanceId = UUID()
        self.parent = parent
        self.transitionDelegate = nil
        self.context = context
        var destinationsMap: [Context.Identifier: ContextTransition] = [:]
        var state: [Context.Identifier: ContextTransition] = [:]
        if let destinations = model.application.map.map[context.identifier] {
            for destination in destinations {
                destinationsMap[destination.destination] = destination
                state[destination.destination] = destination.unfulfilledTransition()
            }
        }
        self.destinationsMap = destinationsMap
        self.state = state
    }
    
    func actionPerformed(_ interaction: ElementInteraction) {
        for destinationScreenId in state.keys {
            if let lhs = state[destinationScreenId], let rhs = destinationsMap[destinationScreenId] {
                var actionsRequired = rhs.actions
                var actionsCompleted = lhs.actions
                actionsRequired.removeFirst(actionsCompleted.count)
                // Check that the next action in sequence is the one which took place
                guard let nextActionRequired = actionsRequired.first, nextActionRequired == interaction else {
                    continue
                }
                let isLastActionRequired = actionsRequired.count <= 1
                if isLastActionRequired { // Perform transition
                    transitionDelegate?.transitionContext(rhs)
                } else {
                    // Update context
                    actionsCompleted.append(interaction)
                    state[destinationScreenId] = ContextTransition(destination: destinationScreenId,
                                                                   actions: actionsCompleted,
                                                                   direction: lhs.direction)
                }
            }
        }
    }
}

extension ContextInstance: ContextTransitioning {
    func transitionContext(_ transition: ContextTransition) {
        
    }
}
