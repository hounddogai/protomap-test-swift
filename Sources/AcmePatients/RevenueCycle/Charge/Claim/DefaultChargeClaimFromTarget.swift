import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimTargetsForClaim(_ items: [ClaimTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDefaultChargeClaimsFromTarget(_ items: [ClaimTarget]) -> [DefaultChargeClaim] {
        var out: [DefaultChargeClaim] = []
        for item in items {
            let derived = newDefaultChargeClaim(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveDefaultChargeClaim(_ item: DefaultChargeClaim) -> String {
        return classifyClaimTarget(item.netLoad())
    }
}
