//
//  ElementInteractionType.swift
//  Skylark
//
//  Created by Ross Butler on 3/3/19.
//

import Foundation

enum ElementInteractionType: String, Codable {
    case existence
    case tap
    case doubleTap = "double-tap"
    case press
    case twoFingerTap = "two-finger-tap"
    case swipeLeft = "swipe-left"
    case swipeRight = "swipe-right"
    case swipeUp = "swipe-up"
    case swipeDown = "swipe-down"
}
