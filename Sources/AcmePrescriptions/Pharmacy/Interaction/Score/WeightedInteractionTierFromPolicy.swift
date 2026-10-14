import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryPoliciesForTier(_ items: [InventoryPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveWeightedInteractionTiersFromPolicy(_ items: [InventoryPolicy]) -> [WeightedInteractionTier] {
        var out: [WeightedInteractionTier] = []
        for item in items {
            let derived = newWeightedInteractionTier(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreWeightedInteractionTier(_ item: WeightedInteractionTier) -> String {
        return normalizeInventoryPolicyCode(item.code)
    }
}
