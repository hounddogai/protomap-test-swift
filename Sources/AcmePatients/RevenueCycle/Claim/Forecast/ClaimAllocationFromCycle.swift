import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationCyclesForAllocation(_ items: [AuthorizationCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveClaimAllocationsFromCycle(_ items: [AuthorizationCycle]) -> [ClaimAllocation] {
        var out: [ClaimAllocation] = []
        for item in items {
            let derived = newClaimAllocation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveClaimAllocation(_ item: ClaimAllocation) -> Double {
        return authorizationCycleWeight(3, active: true)
    }
}
