import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredWorklistAdjustmentsForBatch(_ items: [TieredWorklistAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalStudyBatchesFromAdjustment(_ items: [TieredWorklistAdjustment]) -> [SeasonalStudyBatch] {
        var out: [SeasonalStudyBatch] = []
        for item in items {
            let derived = newSeasonalStudyBatch(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankSeasonalStudyBatch(_ item: SeasonalStudyBatch) -> String {
        return classifyAdaptiveWorklistNotice(item.measuredValue())
    }
}
