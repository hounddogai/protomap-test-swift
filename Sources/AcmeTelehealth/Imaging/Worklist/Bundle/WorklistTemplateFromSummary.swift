import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalReadSummariesForTemplate(_ items: [RegionalReadSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveWorklistTemplatesFromSummary(_ items: [RegionalReadSummary]) -> [WorklistTemplate] {
        var out: [WorklistTemplate] = []
        for item in items {
            let derived = newWorklistTemplate(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileWorklistTemplate(_ item: WorklistTemplate) -> String {
        return defaultReadLedgerBucket(item.weightedTotal())
    }
}
