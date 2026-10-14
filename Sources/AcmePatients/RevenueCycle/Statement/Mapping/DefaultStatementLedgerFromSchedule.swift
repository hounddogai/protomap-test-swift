import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAdaptiveStatementSchedulesForLedger(_ items: [AdaptiveStatementSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveDefaultStatementLedgersFromSchedule(_ items: [AdaptiveStatementSchedule]) -> [DefaultStatementLedger] {
        var out: [DefaultStatementLedger] = []
        for item in items {
            let derived = newDefaultStatementLedger(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planDefaultStatementLedger(_ item: DefaultStatementLedger) -> String {
        return normalizeBatchedStatementReservationCode(item.code)
    }
}
