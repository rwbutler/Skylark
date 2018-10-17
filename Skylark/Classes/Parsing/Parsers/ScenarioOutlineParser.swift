//
//  ScenarioOutlineParser.swift
//  Skylark
//
//  Created by Ross Butler on 10/1/18.
//

import Foundation

struct ScenarioOutlineParser {
    func scenariosWithExampleSubstitutions(scenario: String, outline: ScenarioOutline = .outline) -> [String] {
        guard let examplesText = examples(scenario: scenario) else { return [] }
        let examplesTextRows = examplesText.split(separator: "\n")
        let rows: [[String]] = examplesTextRows.compactMap({ row in
            guard let firstPipeIndex = row.firstIndex(of: "|"),
                let lastPipeIndex = row.lastIndex(of: "|") else { return nil }
            let startIndex = row.index(after: firstPipeIndex)
            let trimmedRow = row[startIndex..<lastPipeIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            let columns = trimmedRow.split(separator: "|")
            // Map String.SubSequences to Strings
            return columns.map({ String($0) })
        })
        
        // Remove examples table from the template to be parameterized
        var scenarioTemplate = scenario.replacingOccurrences(of: examplesText, with: "")
        scenarioTemplate = scenarioTemplate.replacingOccurrences(of: "examples:", with: "")
        
        switch outline {
        case .outline:
            guard let keys = rows.first else { return [] }
            let parameterMaps: [[String: String]] = rows.dropFirst().map({ row in
                return parameterSet(keys: keys, values: row)
            })
            return scenarios(template: scenarioTemplate, parameterMaps: parameterMaps)
        case .permutations:
            let examplesColumns = columns(rows: rows)
             let parameterReplacementsMap: [String: [String]] = Dictionary(examplesColumns.compactMap({ column in
             guard let key = column.first else { return nil }
             return (key, Array(column.dropFirst()))
             }))
             let parameterMaps = permutations(parameterMap: parameterReplacementsMap)
            return scenarios(template: scenarioTemplate, parameterMaps: parameterMaps)
        }
    }
}

private extension ScenarioOutlineParser {
    
    /// Converts an array of rows into an array of columns
    func columns(rows: [[String]]) -> [[String]] {
        return rows[0].indices.map { col in
            rows.indices.map { row in
                rows[row][col]
            }
        }
    }
    
    /// Given a scenario template, yields scenarios with parameters substituted for values in the provided map
    func scenarios(template: String, parameterMaps: [[String: String]]) -> [String] {
        return parameterMaps.map({ parameterMap in
            return parameterMap.reduce(template) { (scenario, replacement) in
                let (exampleName, exampleValue) = replacement
                return scenario.replacingOccurrences(of: "<\(exampleName)>", with: exampleValue)
            }
        })
    }
    
    /// Extracts the examples portion of a scenario (if one exists)
    func examples(scenario: String) -> String? {
        let scenarioRange = NSRange(location: 0, length: scenario.count)
        // swiftlint:disable:next force_try - We know that the following regular expression will compile
        let examplesRegEx = try! NSRegularExpression(pattern: "\\|.+\\|", options: [.dotMatchesLineSeparators])
        
        if let examplesMatch = examplesRegEx.firstMatch(in: scenario, options: [], range: scenarioRange) {
            let examplesStr = (scenario as NSString).substring(with: examplesMatch.range)
            return examplesStr
        }
        return nil
    }
    
    /// Yields all permutations of the given parameter mapping
    /**
     For example:
     
     ["start": ["12", "20"], "eat": ["5", "6"]]
     
     yields:
     
     [["start": "12", "eat": "5"],
     ["start": "12", "eat": "6"],
     ["start": "20", "eat": "5"],
     ["start": "20", "eat": "6"]]
     */
    func permutations(parameterMap: [String: [String]]) -> [[String: String]] {
        var permutations: [[String: String]] = []
        
        for (exampleName, exampleReplacement) in parameterMap {
            var temp: [[String: String]] = []
            
            for replacement in exampleReplacement {
                guard !permutations.isEmpty else {
                    temp.append([exampleName: replacement])
                    continue
                }
                for permutation in permutations {
                    var newPermutation: [String: String] = [exampleName: replacement]
                    newPermutation.merge(permutation) { (current, _) in current }
                    temp.append(newPermutation)
                }
            }
            permutations = temp
        }
        return permutations
    }
    
    func parameterSet(keys: [String], values: [String]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in zip(keys, values) {
            result[key] = value
        }
        return result
    }
}
