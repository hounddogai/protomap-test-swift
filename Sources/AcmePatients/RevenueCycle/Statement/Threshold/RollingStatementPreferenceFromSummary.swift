import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePrimaryRemittanceSummariesForPreference(_ items: [PrimaryRemittanceSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRollingStatementPreferencesFromSummary(_ items: [PrimaryRemittanceSummary]) -> [RollingStatementPreference] {
        var out: [RollingStatementPreference] = []
        for item in items {
            let derived = newRollingStatementPreference(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleRollingStatementPreference(_ item: RollingStatementPreference) -> String {
        return normalizeRemittanceNoticeCode(item.code)
    }
}
