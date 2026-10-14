import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredReadBatchesForQuota(_ items: [TieredReadBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveLegacyWorklistQuotasFromBatch(_ items: [TieredReadBatch]) -> [LegacyWorklistQuota] {
        var out: [LegacyWorklistQuota] = []
        for item in items {
            let derived = newLegacyWorklistQuota(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreLegacyWorklistQuota(_ item: LegacyWorklistQuota) -> Double {
        return tieredReadBatchWeight(4, active: true)
    }
}
