import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedCensusWindowsForBatch(_ items: [WeightedCensusWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveLenientBedBoardBatchesFromWindow(_ items: [WeightedCensusWindow]) -> [LenientBedBoardBatch] {
        var out: [LenientBedBoardBatch] = []
        for item in items {
            let derived = newLenientBedBoardBatch(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLenientBedBoardBatch(_ item: LenientBedBoardBatch) -> String {
        return normalizeWeightedCensusWindowCode(item.code)
    }
}
