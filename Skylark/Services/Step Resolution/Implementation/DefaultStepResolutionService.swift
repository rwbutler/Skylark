//
//  SkylarkStepResolutionService.swift
//  Skylark
//
//  Created by Ross Butler on 3/2/19.
//

import Foundation
import XCTest

class DefaultStepResolutionService: StepResolutionService {
    
    /// Identifier of the current screen in the application.
    private var context: ContextInstance
    private let contextManager: ContextManagementService
    // Registered steps are programmatic rather than from configuration.
    private static var contextualRegisteredSteps: [Context.Identifier: [ParameterisedStepType: Evaluable]] = [:]
    private let model: SkylarkConfiguration
    // Registered steps are programmatic rather than from configuration.
    private static var registeredSteps: [ParameterisedStepType: Evaluable] = [:]
    private var testCase: XCTestCase
    private let timeout: Double = 10.0
    
    init(contextManager: ContextManagementService, model: SkylarkConfiguration, testCase: XCTestCase) {
        self.context = contextManager.currentContext()
        self.contextManager = contextManager
        self.model = model
        self.testCase = testCase
        contextManager.addObserver(self)
    }
    
    func stepWithoutGherkinPrefix(step: String) -> String {
        let prefixes = ["given that", "given", "when", "then", "and", "or", "but"]
        for prefix in prefixes where step.starts(with: prefix) {
            let stepIndexAfterPrefix = step.index(step.startIndex, offsetBy: prefix.count)
            let stepWithoutPrefix = String(step[stepIndexAfterPrefix..<step.endIndex])
            return stepWithoutPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return step
    }
    
    /// Determines whether or not the step is commented out on the individual line level.
    private func stepIsCommentedOut(_ step: String) -> Bool {
        let commentStrs = ["#", "//"]
        let isCommentedOut = commentStrs.reduce(false) { (isCommentedOut, commentStr) -> Bool in
            return step.starts(with: commentStr) || isCommentedOut
        }
        return isCommentedOut
    }
    
    public func resolve(step: String) -> Evaluable? {
        var trimmedStep = step.trimmingCharacters(in: .whitespacesAndNewlines) // trim whitespace
        guard !stepIsCommentedOut(trimmedStep) else {
            return SimpleStep({ return true })
        }
        
        trimmedStep = stepWithoutGherkinPrefix(step: trimmedStep)
        guard let currentScreen = screen(id: context.context.identifier, model: model) else { return nil }
        var manualSteps = type(of: self).registeredSteps
        if let stepsForScreen = type(of: self).contextualRegisteredSteps[currentScreen.identifier] {
            manualSteps.merge(dict: stepsForScreen)
        }
        for manualStep in manualSteps.keys {
            if case .registered(let stepDefinition) = manualStep, isMatch(step: trimmedStep, potentialMatchingStepString: stepDefinition) {
                return manualSteps[manualStep]
            }
        }
        
        var screenElements = currentScreen.elements
        let keyboard = Element(identifier: "keyboard", name: "keyboard", type: .keyboards)
        if screenElements[.keyboards] == nil {
            screenElements[.keyboards] = [keyboard]
        }
        let stepsForScreens = steps(elementType: ElementType.screen, screen: currentScreen)
        
        // Determine whether this step is attempting to check whether a screen is displayed.
        for stepForScreen in stepsForScreens {
            if case .existence(let existenceTemplates) = stepForScreen {
                for existenceTemplate in existenceTemplates {
                    let matchByName = substituteParameter(template: existenceTemplate, substitution: currentScreen.name)
                    let matchById = substituteParameter(template: existenceTemplate, substitution: currentScreen.identifier)
                    if isMatch(step: trimmedStep, potentialMatchingStepString: matchByName)
                        || isMatch(step: trimmedStep, potentialMatchingStepString: matchById) {
                        return screenExistence(element: currentScreen)
                    }
                }
            }
        }
        // Generate steps for all known elements on screen
        for elementType in screenElements.keys {
            if let elementsOfType = screenElements[elementType] {
                let stepsForElementsOfType = steps(elementType: elementType, screen: currentScreen)
                let potentialMatches = potentialSteps(elements: elementsOfType, parameterisedSteps: stepsForElementsOfType)
                for potentialMatch in potentialMatches {
                    if isMatch(step: trimmedStep, potentialMatch: potentialMatch) {
                        return evaluable(matchingStep: potentialMatch)
                    }
                }
            }
        }
        debugPrint("No step found matching '\(step)' for \(context.context.name) context.") // TODO: Logging
        return nil
    }
    
    func register(step: String, evaluable: Evaluable) {
        register(step: step, evaluable: evaluable, screen: nil)
    }
    
    func register(step: String, evaluable: Evaluable, screen: Context.Identifier? = nil) {
        guard let screenId = screen else {
            type(of: self).registeredSteps[.registered(step)] = evaluable
            return
        }
        if var stepsForScreen = type(of: self).contextualRegisteredSteps[screenId] {
            stepsForScreen[.registered(step)] = evaluable
            type(of: self).contextualRegisteredSteps[screenId] = stepsForScreen
        } else {
            let stepsForScreen: [ParameterisedStepType: Evaluable] = [.registered(step): evaluable]
            type(of: self).contextualRegisteredSteps[screenId] = stepsForScreen
        }
    }
    
    func unregisterSteps() {
        type(of: self).registeredSteps = [:]
        type(of: self).contextualRegisteredSteps = [:]
    }
    
    func unregisterSteps(context: Context.Identifier) {
        type(of: self).contextualRegisteredSteps[context] = [:]
    }
    
    /// Updates the test case used to the current one.
    func updateTestCase(_ testCase: XCTestCase) {
        self.testCase = testCase
    }
    
}

extension DefaultStepResolutionService: ContextTransitioned {
    func transitionedToContext(_ context: ContextInstance) {
        self.context = context
    }
}

private extension DefaultStepResolutionService {
    func screen(id: Context.Identifier, model: SkylarkConfiguration) -> Context? {
        return model.application.contexts[id]
    }
    
    private func evaluable(matchingStep: PotentialMatchingStep) -> Evaluable {
        let element = matchingStep.element
        switch matchingStep.interaction {
        case .existence:
            return existence(element: matchingStep.element)
        case .tap:
            return tap(element: matchingStep.element)
        case .doubleTap:
            return performAction(element: element, action: {
                if let query = element.type.xcuiElement?[element.identifier] {
                    query.doubleTap()
                }
            })()
        case .press:
            return performAction(element: element, action: {
                if let query = element.type.xcuiElement?[element.identifier] {
                    query.press(forDuration: 1.0)
                }
            })()
        case .twoFingerTap:
            return performAction(element: element, action: {
                if let query = element.type.xcuiElement?[element.identifier] {
                    query.twoFingerTap()
                }
            })()
        case .swipeLeft:
            return performAction(element: element, action: {
                if let query = element.type.xcuiElement?[element.identifier] {
                    query.swipeLeft()
                }
            })()
        case .swipeRight:
            return performAction(element: element, action: {
                if let query = element.type.xcuiElement?[element.identifier] {
                    query.swipeRight()
                }
            })()
        case .swipeUp:
            return performAction(element: element, action: {
                if let query = element.type.xcuiElement?[element.identifier] {
                    query.swipeUp()
                }
            })()
        case .swipeDown:
            return performAction(element: element, action: {
                if let query = element.type.xcuiElement?[element.identifier] {
                    query.swipeDown()
                }
            })()
        }
    }
    
    func performAction(element: Element, action: @escaping (() -> Void)) -> (() -> Evaluable) {
        return {
            let query = element.type.xcuiElement
            let actionBlock: () -> Void = {
                guard let query = query  else { return }
                var elem = query[element.identifier]
                if element.type == .cells {
                    elem.scrollToCell()
                }
                if !elem.exists {
                    elem = query[element.identifier.capitalized]
                }
                action()
                let interaction = ElementInteraction(action: .tap, element: element.identifier)
                self.contextManager.actionPerformed(interaction)
            }
            let evaluable = SimpleStep({
                actionBlock() // If there is no action to perform then step passes
                return true
            })
            return evaluable
        }
    }
    
    func tap(element: Element) -> Evaluable {
        let query = element.type.xcuiElement
        let tapBlock: () -> Bool = {
            guard let query = query  else { return false }
            
            // Try multiple identifiers for the element in the event that the identifier provided cannot be found.
            let elemIds = [element.identifier, element.name, element.identifier.capitalized, element.name.capitalized,
                           element.identifier.lowercased(), element.name.lowercased(), element.identifier.uppercased(), element.name.uppercased()]

            for elementId in elemIds {
                let elem = query[elementId]
                if element.type == .cells {
                    elem.scrollToCell()
                }
                let interaction = ElementInteraction(action: .tap, element: element.identifier)
                self.contextManager.actionPerformed(interaction)
                if elem.waitForExistence(timeout: 2.0) {
                    elem.tap()
                    self.contextManager.actionPerformed(interaction)
                    return true
                } else if element.type == .cells {
                    let cellText = XCUIApplication().staticTexts[elementId]
                    if cellText.exists {
                        cellText.tap()
                        self.contextManager.actionPerformed(interaction)
                        return true
                    }
                }
            }
            return false
        }
        let evaluable = SimpleStep({
            return tapBlock()
        })
        return evaluable
    }
    
    func screenExistence(element: Context) -> Evaluable {
        var screenElements = element.elements.values.flatMap { $0 }.filter { !$0.isTransient }
        let isDisplayedBlock: () -> Bool = {
            let requiredElementCount = 3
            var foundElementCount = 0
            // Check #`requiredElementCount` randomly-selected elements exist.
            let elementsRequired = (screenElements.count < requiredElementCount) ? screenElements.count : requiredElementCount
            while foundElementCount < elementsRequired && !screenElements.isEmpty {
                let randomElemIdx = Int.random(in: 0 ..< screenElements.count)
                let randomElement = screenElements[randomElemIdx]
                let existenceCheck = self.existence(element: randomElement)
                if existenceCheck.evaluate() {
                    foundElementCount += 1
                }
                screenElements.remove(at: randomElemIdx)
            }
            return foundElementCount == elementsRequired
        }
        return SimpleStep(isDisplayedBlock)
    }
    
    func existence(element: Element) -> Evaluable {
        let query = element.type.xcuiElement
        let discovery = element.discovery
        let isDisplayedBlock: () -> Bool = {
            guard let query = query  else { return false }
            var elem = query[element.identifier]
            
            switch element.type {
            case .keyboards:
                // swiftlint:disable:next empty_count
                let keyboardShown = XCUIApplication().keyboards.count > 0
                return keyboardShown
            case .text:
                let predicate: NSPredicate
                let elementId  = element.identifier
                if elementId.contains("'") {
                    predicate = NSPredicate(format: "label CONTAINS[cd] \"\(element.identifier)\"")
                } else {
                    predicate = NSPredicate(format: "label CONTAINS[cd] '\(element.identifier)'")
                }
                elem = query.matching(predicate).firstMatch
                _ = elem.waitForExistence(timeout: self.timeout)
                return elem.exists
            case .cells:
                let numSwipes = 5
                switch discovery {
                case .none:
                    break
                case .swipeUp:
                    elem.swipeUp(count: numSwipes)
                case .swipeDown:
                    elem.swipeDown(count: numSwipes)
                }
                 _ = elem.waitForExistence(timeout: self.timeout)
                return elem.exists
            default:
                switch discovery {
                case .none:
                    _ = elem.waitForExistence(timeout: self.timeout)
                case .swipeUp:
                    elem.swipeUpAndWait(timeout: self.timeout)
                case .swipeDown:
                    elem.swipeDownAndWait(timeout: self.timeout)
                }
                return elem.exists
            }
            /*let exists = (query == XCUIApplication().navigationBars)
                ? NSPredicate(format: "identifier LIKE '\(element.identifier)'")
                : NSPredicate(format: "exists == YES")
            let expectation = self.testCase.expectation(for: exists, evaluatedWith: elem, handler: nil)
            self.testCase.wait(for: [expectation], timeout: self.timeout, enforceOrder: true)*/
        }
        return SimpleStep(isDisplayedBlock)
    }
    
    func potentialSteps(elements: [Element], parameterisedSteps: [ParameterisedStepType]) -> [PotentialMatchingStep] {
        var result: [PotentialMatchingStep] = []
        for element in elements {
            for parameterisedStep in parameterisedSteps {
                switch parameterisedStep {
                case .existence(let existenceSteps):
                    let potentials = existenceSteps.map { PotentialMatchingStep(element: element, interaction: .existence, template: $0) }
                    result.append(contentsOf: potentials)
                case .interaction(let interactionSteps):
                    let potentials: [[PotentialMatchingStep]] = interactionSteps.compactMap { x in
                        guard let interaction = ElementInteractionType(rawValue: x.key) else {
                            return nil
                        }
                        return x.value.map { interactionStep in
                            return PotentialMatchingStep(element: element, interaction: interaction, template: interactionStep)
                        }
                    }
                    result.append(contentsOf: potentials.flatMap { $0 })
                case .registered:
                    continue
                }
            }
        }
        return result
    }
    
    func isMatch(step: String, potentialMatch: PotentialMatchingStep) -> Bool {
        let matchByName = substituteParameter(template: potentialMatch.template, substitution: potentialMatch.element.name)
        let matchById = substituteParameter(template: potentialMatch.template, substitution: potentialMatch.element.identifier)
        if isMatch(step: step, potentialMatchingStepString: matchByName) || isMatch(step: step, potentialMatchingStepString: matchById) {
            return true
        }
        return false
    }
    
    func isMatch(step: String, potentialMatchingStepString: String) -> Bool {
        return step.lowercased() == potentialMatchingStepString.lowercased()
    }
    
    private func substituteParameter(template: String, substitution: String) -> String {
        return template.replacingOccurrences(of: "$PARAMETER", with: substitution)
    }
    
    func steps(elementType: ElementType, screen: Context) -> [ParameterisedStepType] {
        var applicationLevelSteps = model.application.steps
        if let screenLevelSteps = screen.steps {
            applicationLevelSteps.merge(dict: screenLevelSteps)
        }
        return applicationLevelSteps[elementType] ?? []
    }
    
}
