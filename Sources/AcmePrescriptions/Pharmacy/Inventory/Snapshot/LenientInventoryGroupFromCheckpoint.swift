import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeSeasonalInteractionCheckpointsForGroup(_ items: [SeasonalInteractionCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveLenientInventoryGroupsFromCheckpoint(_ items: [SeasonalInteractionCheckpoint]) -> [LenientInventoryGroup] {
        var out: [LenientInventoryGroup] = []
        for item in items {
            let derived = newLenientInventoryGroup(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankLenientInventoryGroup(_ item: LenientInventoryGroup) -> Double {
        return pendingInteractionVarianceWeight(7, active: true)
    }
}
