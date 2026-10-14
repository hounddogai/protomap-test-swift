import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalPoliciesForPreference(_ items: [GoalPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientRiskScorePreferencesFromPolicy(_ items: [GoalPolicy]) -> [LenientRiskScorePreference] {
        var out: [LenientRiskScorePreference] = []
        for item in items {
            let derived = newLenientRiskScorePreference(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveLenientRiskScorePreference(_ item: LenientRiskScorePreference) -> String {
        return goalPlanBucket(item.adjustedTotal())
    }
}
