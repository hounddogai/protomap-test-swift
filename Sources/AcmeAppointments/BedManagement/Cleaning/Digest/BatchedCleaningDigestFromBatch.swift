import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferBatchesForDigest(_ items: [TransferBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedCleaningDigestsFromBatch(_ items: [TransferBatch]) -> [BatchedCleaningDigest] {
        var out: [BatchedCleaningDigest] = []
        for item in items {
            let derived = newBatchedCleaningDigest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignBatchedCleaningDigest(_ item: BatchedCleaningDigest) -> String {
        return transferManifestBucket(item.weightedVolume())
    }
}
