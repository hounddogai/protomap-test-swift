import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimTargetsForTarget(_ items: [ClaimTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDefaultAuthorizationTargetsFromTarget(_ items: [ClaimTarget]) -> [DefaultAuthorizationTarget] {
        var out: [DefaultAuthorizationTarget] = []
        for item in items {
            let derived = newDefaultAuthorizationTarget(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeDefaultAuthorizationTarget(_ item: DefaultAuthorizationTarget) -> Double {
        return fallbackClaimDraftWeight(3, active: true)
    }
}
