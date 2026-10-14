import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargePoliciesForPolicy(_ items: [ChargePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveLenientClaimPoliciesFromPolicy(_ items: [ChargePolicy]) -> [LenientClaimPolicy] {
        var out: [LenientClaimPolicy] = []
        for item in items {
            let derived = newLenientClaimPolicy(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateLenientClaimPolicy(_ item: LenientClaimPolicy) -> String {
        return normalizeChargePolicyCode(item.code)
    }
}
