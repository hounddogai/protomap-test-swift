import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialScoresForSchedule(_ items: [DenialScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStatementSchedulesFromScore(_ items: [DenialScore]) -> [StatementSchedule] {
        var out: [StatementSchedule] = []
        for item in items {
            let derived = newStatementSchedule(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchStatementSchedule(_ item: StatementSchedule) -> String {
        return classifyRollingDenialRule(item.adjustedTotal())
    }
}
