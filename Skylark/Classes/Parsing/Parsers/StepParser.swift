//
//  StepParser.swift
//  Skylark
//
//  Created by Ross Butler on 9/27/18.
//

import Foundation

struct StepParser: Parser {
    
    // MARK: Type defintions
    typealias Model = StepDefinitions
    
    // MARK: Dependencies
    fileprivate let pageParser = PageParser()
    
    func parse(bundle: Bundle) -> [StepDefinitions]? {
        let jsonExtension: String = "\(FileExtension.json)"
        
        // Search for a user-defined steps file first
        for aBundle in Bundle.allBundles where aBundle != bundle {
            if let stepsFileURL = aBundle.url(forResource: "Steps", withExtension: jsonExtension) {
                return stepsFromJSONFile(bundle: bundle, url: stepsFileURL)
            }
        }
        
        // Fallback to bundled steps file
        guard let bundleStepsFileURL = bundle.url(forResource: "Steps", withExtension: jsonExtension) else {
            return nil
        }
        return stepsFromJSONFile(bundle: bundle, url: bundleStepsFileURL)
    }
}

// Private API
private extension StepParser {
    
    private func stepsDictFromJSONFile(url: URL) -> [String: [String: [String]]]? {
        guard let stepsFileData = try? Data(contentsOf: url, options: []) else {
            return nil
        }
        guard let stepsFileJSON = try? JSONSerialization
            .jsonObject(with: stepsFileData, options: .allowFragments) else {
                return nil
        }
        return stepsFileJSON as? [String: [String: [String]]]
    }
    
    /// Produces a Page model object from the JSON file at the specified URL.
    func stepsFromJSONFile(bundle: Bundle, url: URL) -> [StepDefinitions]? {
        
        var stepDefinitions: [StepDefinitions] = []
        guard let stepsDict = stepsDictFromJSONFile(url: url),
            let pages = pageParser.parse(bundle: bundle) else {
                return nil
        }
        
        for page in pages {
            if let pageStepDefinitions = stepsDict["pages"]?["existence"] {
                stepDefinitions.append(StepDefinitions.page(page: page, stepDefinitions: pageStepDefinitions))
            }
            for elementType in page.elements.keys {
                // Note: We currently only support checking keyboard exists
                guard elementType != .keyboards else {
                    if let keyboardStepDefinitions = stepsDict[elementType.description]?["existence"] {
                        stepDefinitions.append(StepDefinitions.keyboard(pageName: page.name,
                                                                        stepDefinitions: keyboardStepDefinitions))
                    }
                    continue
                }
                if let elementStepDefinitions = stepsDict[elementType.description] {
                    guard let elementsOfType = page.elements[elementType] else { continue }
                    for elementOfType in elementsOfType {
                        stepDefinitions.append(StepDefinitions.element(pageName: page.name, element: elementOfType,
                                                                       query: elementType,
                                                                       stepDefinitions: elementStepDefinitions))
                    }
                }
            }
        }
        return stepDefinitions
    }
}
