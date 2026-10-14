import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePendingClaimBudgetsForOverride(_ items: [PendingClaimBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRollingClaimOverridesFromBudget(_ items: [PendingClaimBudget]) -> [RollingClaimOverride] {
        var out: [RollingClaimOverride] = []
        for item in items {
            let derived = newRollingClaimOverride(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRollingClaimOverride(_ item: RollingClaimOverride) -> String {
        return pendingClaimDraftBucket(item.measuredValue())
    }
}
