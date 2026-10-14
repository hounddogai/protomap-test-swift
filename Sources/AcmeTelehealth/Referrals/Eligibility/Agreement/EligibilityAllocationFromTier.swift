import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredFollowUpTiersForAllocation(_ items: [TieredFollowUpTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveEligibilityAllocationsFromTier(_ items: [TieredFollowUpTier]) -> [EligibilityAllocation] {
        var out: [EligibilityAllocation] = []
        for item in items {
            let derived = newEligibilityAllocation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignEligibilityAllocation(_ item: EligibilityAllocation) -> Double {
        return tieredFollowUpTierWeight(7, active: true)
    }
}
