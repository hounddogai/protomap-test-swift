import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationDigestsForBatch(_ items: [IsolationDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCleaningBatchesFromDigest(_ items: [IsolationDigest]) -> [CleaningBatch] {
        var out: [CleaningBatch] = []
        for item in items {
            let derived = newCleaningBatch(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeCleaningBatch(_ item: CleaningBatch) -> String {
        return isolationScoreBucket(item.measuredValue())
    }
}
