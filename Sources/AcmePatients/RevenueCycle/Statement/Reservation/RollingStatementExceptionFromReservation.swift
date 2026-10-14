import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeGlobalStatementReservationsForException(_ items: [GlobalStatementReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRollingStatementExceptionsFromReservation(_ items: [GlobalStatementReservation]) -> [RollingStatementException] {
        var out: [RollingStatementException] = []
        for item in items {
            let derived = newRollingStatementException(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateRollingStatementException(_ item: RollingStatementException) -> String {
        return statementPlanBucket(item.netTotal())
    }
}
