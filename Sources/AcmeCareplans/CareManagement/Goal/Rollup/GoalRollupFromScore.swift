import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachScoresForRollup(_ items: [OutreachScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveGoalRollupsFromScore(_ items: [OutreachScore]) -> [GoalRollup] {
        var out: [GoalRollup] = []
        for item in items {
            let derived = newGoalRollup(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateGoalRollup(_ item: GoalRollup) -> String {
        return normalizeOutreachAllocationCode(item.code)
    }
}
