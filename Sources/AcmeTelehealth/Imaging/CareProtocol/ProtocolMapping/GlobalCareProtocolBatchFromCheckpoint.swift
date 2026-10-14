import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalStudyCheckpointsForBatch(_ items: [GlobalStudyCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveGlobalCareProtocolBatchesFromCheckpoint(_ items: [GlobalStudyCheckpoint]) -> [GlobalCareProtocolBatch] {
        var out: [GlobalCareProtocolBatch] = []
        for item in items {
            let derived = newGlobalCareProtocolBatch(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceGlobalCareProtocolBatch(_ item: GlobalCareProtocolBatch) -> String {
        return globalStudyCheckpointBucket(item.weightedVolume())
    }
}
