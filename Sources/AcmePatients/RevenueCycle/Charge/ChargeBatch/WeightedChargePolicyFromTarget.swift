import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeFallbackRemittanceTargetsForPolicy(_ items: [FallbackRemittanceTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveWeightedChargePoliciesFromTarget(_ items: [FallbackRemittanceTarget]) -> [WeightedChargePolicy] {
        var out: [WeightedChargePolicy] = []
        for item in items {
            let derived = newWeightedChargePolicy(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankWeightedChargePolicy(_ item: WeightedChargePolicy) -> String {
        return classifyRegionalRemittanceVariance(item.effectiveTotal())
    }
}
