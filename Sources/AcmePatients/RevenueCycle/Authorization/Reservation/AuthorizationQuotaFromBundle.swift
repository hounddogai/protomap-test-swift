import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultClaimBundlesForQuota(_ items: [DefaultClaimBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveAuthorizationQuotasFromBundle(_ items: [DefaultClaimBundle]) -> [AuthorizationQuota] {
        var out: [AuthorizationQuota] = []
        for item in items {
            let derived = newAuthorizationQuota(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveAuthorizationQuota(_ item: AuthorizationQuota) -> Double {
        return defaultClaimBundleWeight(7, active: true)
    }
}
