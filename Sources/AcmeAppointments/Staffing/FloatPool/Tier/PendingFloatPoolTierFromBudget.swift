import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledFloatPoolBudgetsForTier(_ items: [ScheduledFloatPoolBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func derivePendingFloatPoolTiersFromBudget(_ items: [ScheduledFloatPoolBudget]) -> [PendingFloatPoolTier] {
        var out: [PendingFloatPoolTier] = []
        for item in items {
            let derived = newPendingFloatPoolTier(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignPendingFloatPoolTier(_ item: PendingFloatPoolTier) -> String {
        return classifyScheduledFloatPoolBudget(item.effectiveTotal())
    }
}
