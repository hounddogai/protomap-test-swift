import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredStudyTiersForBatch(_ items: [TieredStudyTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedModalityBatchesFromTier(_ items: [TieredStudyTier]) -> [CappedModalityBatch] {
        var out: [CappedModalityBatch] = []
        for item in items {
            let derived = newCappedModalityBatch(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCappedModalityBatch(_ item: CappedModalityBatch) -> String {
        return tieredStudyTierBucket(item.effectiveVolume())
    }
}
