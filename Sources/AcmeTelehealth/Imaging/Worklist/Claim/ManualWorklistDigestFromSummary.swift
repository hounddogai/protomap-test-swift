import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingPrioritySummariesForDigest(_ items: [PendingPrioritySummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveManualWorklistDigestsFromSummary(_ items: [PendingPrioritySummary]) -> [ManualWorklistDigest] {
        var out: [ManualWorklistDigest] = []
        for item in items {
            let derived = newManualWorklistDigest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeManualWorklistDigest(_ item: ManualWorklistDigest) -> String {
        return priorityBatchBucket(item.weightedVolume())
    }
}
