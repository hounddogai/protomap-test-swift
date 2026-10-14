import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedClaimAssignmentsForBudget(_ items: [BatchedClaimAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveDefaultRemittanceBudgetsFromAssignment(_ items: [BatchedClaimAssignment]) -> [DefaultRemittanceBudget] {
        var out: [DefaultRemittanceBudget] = []
        for item in items {
            let derived = newDefaultRemittanceBudget(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceDefaultRemittanceBudget(_ item: DefaultRemittanceBudget) -> String {
        return pendingClaimDraftBucket(item.projectedValue())
    }
}
