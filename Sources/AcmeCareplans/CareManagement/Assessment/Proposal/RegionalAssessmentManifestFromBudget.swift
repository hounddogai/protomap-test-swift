import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalBudgetsForManifest(_ items: [GoalBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRegionalAssessmentManifestsFromBudget(_ items: [GoalBudget]) -> [RegionalAssessmentManifest] {
        var out: [RegionalAssessmentManifest] = []
        for item in items {
            let derived = newRegionalAssessmentManifest(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveRegionalAssessmentManifest(_ item: RegionalAssessmentManifest) -> String {
        return classifyGoalTarget(item.adjustedLoad())
    }
}
