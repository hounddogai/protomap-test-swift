import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledLanguageCyclesForBatch(_ items: [ScheduledLanguageCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveRegionalRevocationBatchesFromCycle(_ items: [ScheduledLanguageCycle]) -> [RegionalRevocationBatch] {
        var out: [RegionalRevocationBatch] = []
        for item in items {
            let derived = newRegionalRevocationBatch(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeRegionalRevocationBatch(_ item: RegionalRevocationBatch) -> String {
        return scheduledLanguageCycleBucket(item.adjustedTotal())
    }
}
