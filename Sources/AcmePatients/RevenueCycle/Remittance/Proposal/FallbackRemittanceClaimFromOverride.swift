import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialOverridesForClaim(_ items: [DenialOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveFallbackRemittanceClaimsFromOverride(_ items: [DenialOverride]) -> [FallbackRemittanceClaim] {
        var out: [FallbackRemittanceClaim] = []
        for item in items {
            let derived = newFallbackRemittanceClaim(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectFallbackRemittanceClaim(_ item: FallbackRemittanceClaim) -> String {
        return normalizeScheduledDenialBaselineCode(item.code)
    }
}
