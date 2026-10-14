import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapExceptionsForPreference(_ items: [CareGapException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveGoalPreferencesFromException(_ items: [CareGapException]) -> [GoalPreference] {
        var out: [GoalPreference] = []
        for item in items {
            let derived = newGoalPreference(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceGoalPreference(_ item: GoalPreference) -> String {
        return classifyCareGapRule(item.measuredValue())
    }
}
