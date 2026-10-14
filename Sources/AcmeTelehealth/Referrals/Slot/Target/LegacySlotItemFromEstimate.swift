import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotEstimatesForItem(_ items: [SlotEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacySlotItemsFromEstimate(_ items: [SlotEstimate]) -> [LegacySlotItem] {
        var out: [LegacySlotItem] = []
        for item in items {
            let derived = newLegacySlotItem(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLegacySlotItem(_ item: LegacySlotItem) -> String {
        return slotReservationBucket(item.effectiveExposure())
    }
}
