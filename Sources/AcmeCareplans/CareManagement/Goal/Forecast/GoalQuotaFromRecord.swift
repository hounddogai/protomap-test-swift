import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalRecordsForQuota(_ items: [GoalRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGoalQuotasFromRecord(_ items: [GoalRecord]) -> [GoalQuota] {
        var out: [GoalQuota] = []
        for item in items {
            let derived = newGoalQuota(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankGoalQuota(_ item: GoalQuota) -> String {
        return classifyDefaultGoalPolicy(item.measuredValue())
    }
}
