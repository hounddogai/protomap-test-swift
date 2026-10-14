import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeFallbackRemittanceClaimsForEstimate(_ items: [FallbackRemittanceClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAuthorizationEstimatesFromClaim(_ items: [FallbackRemittanceClaim]) -> [AuthorizationEstimate] {
        var out: [AuthorizationEstimate] = []
        for item in items {
            let derived = newAuthorizationEstimate(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyAuthorizationEstimate(_ item: AuthorizationEstimate) -> String {
        return classifyRemittanceBatch(item.effectiveValue())
    }
}
