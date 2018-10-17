//
//  SkylarkResult.swift
//  Skylark
//
//  Created by Ross Butler on 10/11/18.
//

struct SkylarkResult {
    let passedScenarios: [Scenario]
    let failedScenarios: [Scenario]
    let flakyScenarios: [Scenario]
    
    var scenariosPassed: Int {
        return passedScenarios.count
    }
    
    var scenariosFailed: Int {
        return failedScenarios.count
    }
    
    var scenariosFlaky: Int {
        return flakyScenarios.count
    }
    
    var scenariosExecuted: Int {
        return scenariosPassed + scenariosFailed + scenariosFlaky
    }
    
    var passed: Bool {
        return failedScenarios.isEmpty
            && (scenariosPassed + scenariosFailed + scenariosFlaky != 0)
    }
    
    init(passedScenarios: [Scenario], failedScenarios: [Scenario], flakyScenarios: [Scenario]) {
        self.passedScenarios = passedScenarios
        self.failedScenarios = failedScenarios
        self.flakyScenarios = flakyScenarios
    }
}

extension SkylarkResult: CustomStringConvertible {
    public var description: String {
        var summaryComponents: [String] = []
        var summary = "\n\nTest summary:\n\n\(scenariosExecuted) scenarios"
        if scenariosExecuted > 0 {
            summary.append(" (")
        }
        if scenariosFailed > 0 {
            summaryComponents.append("\(scenariosFailed) failed ❌")
        }
        if scenariosFlaky > 0 {
            summaryComponents.append("\(scenariosFlaky) flaky ⚠️")
        }
        if scenariosPassed > 0 {
            summaryComponents.append("\(scenariosPassed) passed ✅")
        }
        if scenariosExecuted > 0 {
            summary += summaryComponents.joined(separator: ", ")
            summary.append(")")
        }
        summary += "\n\n"
        return summary
    }
}
