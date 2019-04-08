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
    private var context: Context
    private let contextManager: ContextManagementService
    private let model: SkylarkConfiguration
    private let testCase: XCTestCase
    private let timeout: Double = 10.0
    private static var manualSteps: [ParameterisedStepType: Evaluable] = [:]
    private static var manualStepsForScreen: [Screen.Identifier: [ParameterisedStepType: Evaluable]] = [:]
    
    init(context: Screen.Identifier, contextManager: ContextManagementService,
         model: SkylarkConfiguration, testCase: XCTestCase) {
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
    
    public func resolve(step: String) -> Evaluable? {
        // Check whether step is a comment
        guard !step.starts(with: "#") else {
            return SimpleStep({ return true })
        }
        
        let trimmedStep = stepWithoutGherkinPrefix(step: step)
        guard let currentScreen = screen(id: context.screen.identifier, model: model) else { return nil }
        var manualSteps = type(of: self).manualSteps
        if let stepsForScreen = type(of: self).manualStepsForScreen[currentScreen.identifier] {
            manualSteps.merge(dict: stepsForScreen)
        }
        for manualStep in type(of: self).manualSteps.keys {
            if case .manual(let stepDefinition) = manualStep, isMatch(step: trimmedStep,
                                                                      potentialMatchingStepString: stepDefinition) {
                return type(of: self).manualSteps[manualStep]
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
                    let matchById = substituteParameter(template: existenceTemplate,
                                                        substitution: currentScreen.identifier)
                    if isMatch(step: trimmedStep, potentialMatchingStepString: matchByName)
                        || isMatch(step: trimmedStep, potentialMatchingStepString: matchById) {
                        return screenExistence(element: currentScreen)
                    }
                }
            }
        }

        for elementType in screenElements.keys {
            if let elementsOfType = screenElements[elementType] {
                let stepsForElementsOfType = steps(elementType: elementType, screen: currentScreen)
                let potentialMatches = potentialSteps(elements: elementsOfType,
                                                      parameterisedSteps: stepsForElementsOfType)
                for potentialMatch in potentialMatches {
                    if isMatch(step: trimmedStep, potentialMatch: potentialMatch) {
                        return evaluable(matchingStep: potentialMatch)
                    }
                }
            }
        }
        return nil
    }
    
    func register(step: String, evaluable: Evaluable) {
        register(step: step, evaluable: evaluable, screen: nil)
    }

    func register(step: String, evaluable: Evaluable, screen: Screen.Identifier? = nil) {
        guard let screenId = screen else {
            type(of: self).manualSteps[.manual(step)] = evaluable
            return
        }
        if var stepsForScreen = type(of: self).manualStepsForScreen[screenId] {
            stepsForScreen[.manual(step)] = evaluable
            type(of: self).manualStepsForScreen[screenId] = stepsForScreen
        } else {
            let stepsForScreen: [ParameterisedStepType: Evaluable] = [.manual(step): evaluable]
            type(of: self).manualStepsForScreen[screenId] = stepsForScreen
        }
    }
}

extension DefaultStepResolutionService: ContextTransitioned {
    func transitionedToContext(_ context: Context) {
        self.context = context
    }
}

private extension DefaultStepResolutionService {
    func screen(id: Screen.Identifier, model: SkylarkConfiguration) -> Screen? {
        return model.application.screens[id]
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
            let tapBlock: () -> Void = {
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
                tapBlock() // If there is no action to perform then step passes
                return true
            })
            return evaluable
        }
    }
    
    func tap(element: Element) -> Evaluable {
        let query = element.type.xcuiElement
        let tapBlock: () -> Void = {
            guard let query = query  else { return }
            var elem = query[element.identifier]
            if element.type == .cells {
                elem.scrollToCell()
            }
            if !elem.exists {
                elem = query[element.identifier.capitalized]
            }
            
            elem.tap()
            let interaction = ElementInteraction(action: .tap, element: element.identifier)
            self.contextManager.actionPerformed(interaction)
        }
        let evaluable = SimpleStep({
            tapBlock() // If there is no action to perform then step passes
            return true
        })
        return evaluable
    }
    
    func screenExistence(element: Screen) -> Evaluable {
        var screenElements = element.elements.values.flatMap { $0 }
        let isDisplayedBlock: () -> Bool = {
            var elementsLocatedCount = 0
            // Check three randomly-selected elements exist
            let elementsRequired = (screenElements.count < 3) ? screenElements.count : 3
            while elementsLocatedCount < elementsRequired && !screenElements.isEmpty {
                let randomElemIdx = Int.random(in: 0 ..< screenElements.count)
                let randomElement = screenElements[randomElemIdx]
                let existenceCheck = self.existence(element: randomElement)
                if existenceCheck.evaluate() {
                    elementsLocatedCount += 1
                }
                screenElements.remove(at: randomElemIdx)
            }
            return elementsLocatedCount == elementsRequired
        }
        return SimpleStep(isDisplayedBlock)
    }
    
    func existence(element: Element) -> Evaluable {
        let query = element.type.xcuiElement
        let isDisplayedBlock: () -> Bool = {
            guard let query = query  else { return false }
            var elem = query[element.identifier]
            
            switch element.type {
            case .cells:
                elem.scrollToCell()
            case .keyboards:
                // swiftlint:disable:next empty_count
                let keyboardShown = XCUIApplication().keyboards.count > 0
                return keyboardShown
            case .text:
                let predicate = NSPredicate(format: "label CONTAINS[cd] '\(element.identifier)'")
                elem = query.matching(predicate).firstMatch
            default:
                elem.scrollToElement()
            }
            
            let exists = (query == XCUIApplication().navigationBars)
                ? NSPredicate(format: "identifier LIKE '\(element.identifier)'")
                : NSPredicate(format: "exists == YES")
            
            let expectation = self.testCase.expectation(for: exists, evaluatedWith: elem, handler: nil)
            self.testCase.wait(for: [expectation], timeout: self.timeout, enforceOrder: true)
            return elem.exists
        }
        return SimpleStep(isDisplayedBlock)
    }
    
    func potentialSteps(elements: [Element], parameterisedSteps: [ParameterisedStepType]) -> [PotentialMatchingStep] {
        var result: [PotentialMatchingStep] = []
        for element in elements {
            for parameterisedStep in parameterisedSteps {
                switch parameterisedStep {
                case .existence(let existenceSteps):
                    let potentials = existenceSteps.map {
                        PotentialMatchingStep(element: element, interaction: .existence, template: $0)
                    }
                    result.append(contentsOf: potentials)
                case .interaction(let interactionSteps):
                    let potentials: [[PotentialMatchingStep]] = interactionSteps.compactMap { x in
                        guard let interaction = ElementInteractionType(rawValue: x.key) else {
                            return nil
                        }
                        return x.value.map { interactionStep in
                            return PotentialMatchingStep(element: element, interaction: interaction,
                                                         template: interactionStep)
                        }
                    }
                    result.append(contentsOf: potentials.flatMap { $0 })
                case .manual:
                    continue
                }
            }
        }
        return result
    }
    
    func isMatch(step: String, potentialMatch: PotentialMatchingStep) -> Bool {
        let matchByName = substituteParameter(template: potentialMatch.template,
                                              substitution: potentialMatch.element.name)
        let matchById = substituteParameter(template: potentialMatch.template,
                                            substitution: potentialMatch.element.identifier)
        if isMatch(step: step, potentialMatchingStepString: matchByName)
            || isMatch(step: step, potentialMatchingStepString: matchById) {
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
    
    func steps(elementType: ElementType, screen: Screen) -> [ParameterisedStepType] {
        var applicationLevelSteps = model.application.steps
        if let screenLevelSteps = screen.steps {
            applicationLevelSteps.merge(dict: screenLevelSteps)
        }
        return applicationLevelSteps[elementType] ?? []
    }
}
