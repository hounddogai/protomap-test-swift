import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLegacySlotThresholdsForBaseline(_ items: [LegacySlotThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveSlotBaselinesFromThreshold(_ items: [LegacySlotThreshold]) -> [SlotBaseline] {
        var out: [SlotBaseline] = []
        for item in items {
            let derived = newSlotBaseline(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateSlotBaseline(_ item: SlotBaseline) -> String {
        return normalizeBatchedSlotTierCode(item.code)
    }
}
