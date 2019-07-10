//
//  ContextTransitioning.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

protocol ContextTransitioning: class {
    func transitionContext(_ transition: ContextTransition)
}

protocol ContextTransitioned: class {
    func transitionedToContext(_ context: ContextInstance)
}
