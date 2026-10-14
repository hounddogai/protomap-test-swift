import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeWeightedChargePoliciesForClaim(_ items: [WeightedChargePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveScheduledDenialClaimsFromPolicy(_ items: [WeightedChargePolicy]) -> [ScheduledDenialClaim] {
        var out: [ScheduledDenialClaim] = []
        for item in items {
            let derived = newScheduledDenialClaim(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitScheduledDenialClaim(_ item: ScheduledDenialClaim) -> String {
        return normalizeWeightedChargePolicyCode(item.code)
    }
}
