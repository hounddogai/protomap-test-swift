import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRollingStatementGroupsForReservation(_ items: [RollingStatementGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveBatchedStatementReservationsFromGroup(_ items: [RollingStatementGroup]) -> [BatchedStatementReservation] {
        var out: [BatchedStatementReservation] = []
        for item in items {
            let derived = newBatchedStatementReservation(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreBatchedStatementReservation(_ item: BatchedStatementReservation) -> String {
        return classifyStatementRule(item.measuredValue())
    }
}
