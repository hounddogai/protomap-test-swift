import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStatementAgreementsForBaseline(_ items: [StatementAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStatementBaselinesFromAgreement(_ items: [StatementAgreement]) -> [StatementBaseline] {
        var out: [StatementBaseline] = []
        for item in items {
            let derived = newStatementBaseline(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeStatementBaseline(_ item: StatementBaseline) -> String {
        return statementSlotBucket(item.projectedTotal())
    }
}
