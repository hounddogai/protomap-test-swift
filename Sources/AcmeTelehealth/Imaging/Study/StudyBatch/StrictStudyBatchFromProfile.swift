import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistProfilesForBatch(_ items: [WorklistProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveStrictStudyBatchesFromProfile(_ items: [WorklistProfile]) -> [StrictStudyBatch] {
        var out: [StrictStudyBatch] = []
        for item in items {
            let derived = newStrictStudyBatch(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankStrictStudyBatch(_ item: StrictStudyBatch) -> String {
        return worklistBudgetBucket(item.adjustedTotal())
    }
}
