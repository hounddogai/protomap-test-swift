import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotBatchesForBaseline(_ items: [SlotBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveFallbackFollowUpBaselinesFromBatch(_ items: [SlotBatch]) -> [FallbackFollowUpBaseline] {
        var out: [FallbackFollowUpBaseline] = []
        for item in items {
            let derived = newFallbackFollowUpBaseline(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectFallbackFollowUpBaseline(_ item: FallbackFollowUpBaseline) -> Double {
        return slotOverrideWeight(7, active: true)
    }
}
