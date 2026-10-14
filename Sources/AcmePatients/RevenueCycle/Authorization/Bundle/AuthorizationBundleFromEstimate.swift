import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRollingClaimEstimatesForBundle(_ items: [RollingClaimEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveAuthorizationBundlesFromEstimate(_ items: [RollingClaimEstimate]) -> [AuthorizationBundle] {
        var out: [AuthorizationBundle] = []
        for item in items {
            let derived = newAuthorizationBundle(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeAuthorizationBundle(_ item: AuthorizationBundle) -> String {
        return claimAdjustmentBucket(item.measuredValue())
    }
}
