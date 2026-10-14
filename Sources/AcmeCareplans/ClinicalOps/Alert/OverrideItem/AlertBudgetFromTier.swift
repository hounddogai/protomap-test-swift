import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingTiersForBudget(_ items: [RoundingTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveAlertBudgetsFromTier(_ items: [RoundingTier]) -> [AlertBudget] {
        var out: [AlertBudget] = []
        for item in items {
            let derived = newAlertBudget(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveAlertBudget(_ item: AlertBudget) -> Double {
        return roundingMilestoneWeight(8, active: true)
    }
}
