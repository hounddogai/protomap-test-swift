import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationRecordsForRecord(_ items: [IsolationRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func derivePendingCleaningRecordsFromRecord(_ items: [IsolationRecord]) -> [PendingCleaningRecord] {
        var out: [PendingCleaningRecord] = []
        for item in items {
            let derived = newPendingCleaningRecord(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergePendingCleaningRecord(_ item: PendingCleaningRecord) -> String {
        return classifyAdaptiveIsolationReview(item.weightedExposure())
    }
}
