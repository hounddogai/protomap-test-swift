import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialQuotasForPolicy(_ items: [DenialQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveAuthorizationPoliciesFromQuota(_ items: [DenialQuota]) -> [AuthorizationPolicy] {
        var out: [AuthorizationPolicy] = []
        for item in items {
            let derived = newAuthorizationPolicy(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileAuthorizationPolicy(_ item: AuthorizationPolicy) -> String {
        return denialQuotaBucket(item.adjustedValue())
    }
}
