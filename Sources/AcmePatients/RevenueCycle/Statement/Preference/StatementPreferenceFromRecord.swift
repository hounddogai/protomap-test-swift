import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLegacyStatementRecordsForPreference(_ items: [LegacyStatementRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveStatementPreferencesFromRecord(_ items: [LegacyStatementRecord]) -> [StatementPreference] {
        var out: [StatementPreference] = []
        for item in items {
            let derived = newStatementPreference(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeStatementPreference(_ item: StatementPreference) -> Double {
        return legacyStatementRecordWeight(2, active: true)
    }
}
