import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledLanguageLedgersForSummary(_ items: [ScheduledLanguageLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveBatchedWitnessSummariesFromLedger(_ items: [ScheduledLanguageLedger]) -> [BatchedWitnessSummary] {
        var out: [BatchedWitnessSummary] = []
        for item in items {
            let derived = newBatchedWitnessSummary(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitBatchedWitnessSummary(_ item: BatchedWitnessSummary) -> String {
        return normalizeRollingLanguageForecastCode(item.code)
    }
}
