import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeTiersForPolicy(_ items: [ChargeTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveChargePoliciesFromTier(_ items: [ChargeTier]) -> [ChargePolicy] {
        var out: [ChargePolicy] = []
        for item in items {
            let derived = newChargePolicy(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateChargePolicy(_ item: ChargePolicy) -> String {
        return normalizeChargeTierCode(item.code)
    }
}
