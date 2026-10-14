import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeManualChargeOverridesForTier(_ items: [ManualChargeOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveWeightedChargeTiersFromOverride(_ items: [ManualChargeOverride]) -> [WeightedChargeTier] {
        var out: [WeightedChargeTier] = []
        for item in items {
            let derived = newWeightedChargeTier(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateWeightedChargeTier(_ item: WeightedChargeTier) -> String {
        return classifyStrictChargeGroup(item.projectedValue())
    }
}
