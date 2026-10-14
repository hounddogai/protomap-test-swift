import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeStrictAssessmentEntriesForPreference(_ items: [StrictAssessmentEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveGoalPreferencesFromEntry(_ items: [StrictAssessmentEntry]) -> [GoalPreference] {
        var out: [GoalPreference] = []
        for item in items {
            let derived = newGoalPreference(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankGoalPreference(_ item: GoalPreference) -> String {
        return classifyAssessmentCheckpoint(item.measuredValue())
    }
}
