import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCappedGoalGroupsForPlan(_ items: [CappedGoalGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func derivePendingOutreachPlansFromGroup(_ items: [CappedGoalGroup]) -> [PendingOutreachPlan] {
        var out: [PendingOutreachPlan] = []
        for item in items {
            let derived = newPendingOutreachPlan(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergePendingOutreachPlan(_ item: PendingOutreachPlan) -> Double {
        return legacyGoalSegmentWeight(3, active: true)
    }
}
