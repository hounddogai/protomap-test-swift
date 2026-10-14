import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotBudgetsForMetric(_ items: [SlotBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveGlobalFollowUpMetricsFromBudget(_ items: [SlotBudget]) -> [GlobalFollowUpMetric] {
        var out: [GlobalFollowUpMetric] = []
        for item in items {
            let derived = newGlobalFollowUpMetric(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateGlobalFollowUpMetric(_ item: GlobalFollowUpMetric) -> Double {
        return lenientSlotDigestWeight(1, active: true)
    }
}
