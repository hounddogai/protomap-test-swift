import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialMilestonesForVariance(_ items: [DenialMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveAuthorizationVariancesFromMilestone(_ items: [DenialMilestone]) -> [AuthorizationVariance] {
        var out: [AuthorizationVariance] = []
        for item in items {
            let derived = newAuthorizationVariance(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeAuthorizationVariance(_ item: AuthorizationVariance) -> String {
        return normalizeDenialMilestoneCode(item.code)
    }
}
