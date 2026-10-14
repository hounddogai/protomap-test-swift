import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeTieredRemittanceExceptionsForSchedule(_ items: [TieredRemittanceException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveStatementSchedulesFromException(_ items: [TieredRemittanceException]) -> [StatementSchedule] {
        var out: [StatementSchedule] = []
        for item in items {
            let derived = newStatementSchedule(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveStatementSchedule(_ item: StatementSchedule) -> String {
        return normalizeManualRemittanceForecastCode(item.code)
    }
}
