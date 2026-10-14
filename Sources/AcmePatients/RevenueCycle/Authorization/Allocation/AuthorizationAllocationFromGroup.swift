import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimGroupsForAllocation(_ items: [ClaimGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveAuthorizationAllocationsFromGroup(_ items: [ClaimGroup]) -> [AuthorizationAllocation] {
        var out: [AuthorizationAllocation] = []
        for item in items {
            let derived = newAuthorizationAllocation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileAuthorizationAllocation(_ item: AuthorizationAllocation) -> String {
        return claimSegmentBucket(item.netTotal())
    }
}
