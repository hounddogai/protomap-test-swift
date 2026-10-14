import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingBundlesForBudget(_ items: [RoundingBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveOrderSetBudgetsFromBundle(_ items: [RoundingBundle]) -> [OrderSetBudget] {
        var out: [OrderSetBudget] = []
        for item in items {
            let derived = newOrderSetBudget(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeOrderSetBudget(_ item: OrderSetBudget) -> String {
        return pendingRoundingTierBucket(item.measuredValue())
    }
}
