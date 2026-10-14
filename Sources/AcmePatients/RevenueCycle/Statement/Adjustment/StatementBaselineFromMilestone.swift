import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceMilestonesForBaseline(_ items: [RemittanceMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveStatementBaselinesFromMilestone(_ items: [RemittanceMilestone]) -> [StatementBaseline] {
        var out: [StatementBaseline] = []
        for item in items {
            let derived = newStatementBaseline(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planStatementBaseline(_ item: StatementBaseline) -> String {
        return normalizeRemittanceAuditCode(item.code)
    }
}
