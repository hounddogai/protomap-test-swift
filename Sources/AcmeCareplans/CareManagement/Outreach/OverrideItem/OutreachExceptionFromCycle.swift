import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalCyclesForException(_ items: [GoalCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveOutreachExceptionsFromCycle(_ items: [GoalCycle]) -> [OutreachException] {
        var out: [OutreachException] = []
        for item in items {
            let derived = newOutreachException(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeOutreachException(_ item: OutreachException) -> String {
        return normalizeGoalOverrideCode(item.code)
    }
}
