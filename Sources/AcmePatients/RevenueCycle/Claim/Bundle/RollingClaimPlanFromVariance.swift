import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationVariancesForPlan(_ items: [AuthorizationVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRollingClaimPlansFromVariance(_ items: [AuthorizationVariance]) -> [RollingClaimPlan] {
        var out: [RollingClaimPlan] = []
        for item in items {
            let derived = newRollingClaimPlan(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRollingClaimPlan(_ item: RollingClaimPlan) -> Double {
        return adaptiveAuthorizationAuditWeight(4, active: true)
    }
}
