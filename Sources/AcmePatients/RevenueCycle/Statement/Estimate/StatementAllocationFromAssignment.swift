import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeAssignmentsForAllocation(_ items: [ChargeAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveStatementAllocationsFromAssignment(_ items: [ChargeAssignment]) -> [StatementAllocation] {
        var out: [StatementAllocation] = []
        for item in items {
            let derived = newStatementAllocation(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateStatementAllocation(_ item: StatementAllocation) -> String {
        return chargeAssignmentBucket(item.effectiveTotal())
    }
}
