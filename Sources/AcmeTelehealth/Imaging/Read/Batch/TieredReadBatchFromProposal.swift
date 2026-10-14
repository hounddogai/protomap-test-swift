import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityProposalsForBatch(_ items: [ModalityProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredReadBatchesFromProposal(_ items: [ModalityProposal]) -> [TieredReadBatch] {
        var out: [TieredReadBatch] = []
        for item in items {
            let derived = newTieredReadBatch(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankTieredReadBatch(_ item: TieredReadBatch) -> String {
        return weightedModalityTierBucket(item.adjustedLoad())
    }
}
