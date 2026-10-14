import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardBatchesForCheckpoint(_ items: [BedBoardBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveTransferCheckpointsFromBatch(_ items: [BedBoardBatch]) -> [TransferCheckpoint] {
        var out: [TransferCheckpoint] = []
        for item in items {
            let derived = newTransferCheckpoint(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeTransferCheckpoint(_ item: TransferCheckpoint) -> String {
        return bedBoardCheckpointBucket(item.weightedExposure())
    }
}
