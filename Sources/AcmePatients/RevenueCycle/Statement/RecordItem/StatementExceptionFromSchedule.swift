import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementSchedulesForException(_ items: [StatementSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveStatementExceptionsFromSchedule(_ items: [StatementSchedule]) -> [StatementException] {
        var out: [StatementException] = []
        for item in items {
            let derived = newStatementException(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceStatementException(_ item: StatementException) -> Double {
        return batchedStatementGroupWeight(7, active: true)
    }
}
