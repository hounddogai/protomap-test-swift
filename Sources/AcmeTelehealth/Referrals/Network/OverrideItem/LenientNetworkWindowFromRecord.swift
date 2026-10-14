import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRegionalSlotRecordsForWindow(_ items: [RegionalSlotRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveLenientNetworkWindowsFromRecord(_ items: [RegionalSlotRecord]) -> [LenientNetworkWindow] {
        var out: [LenientNetworkWindow] = []
        for item in items {
            let derived = newLenientNetworkWindow(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLenientNetworkWindow(_ item: LenientNetworkWindow) -> String {
        return slotReservationBucket(item.adjustedTotal())
    }
}
