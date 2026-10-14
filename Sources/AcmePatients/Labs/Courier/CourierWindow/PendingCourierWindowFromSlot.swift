import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeSlotsForWindow(_ items: [ReferenceRangeSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingCourierWindowsFromSlot(_ items: [ReferenceRangeSlot]) -> [PendingCourierWindow] {
        var out: [PendingCourierWindow] = []
        for item in items {
            let derived = newPendingCourierWindow(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balancePendingCourierWindow(_ item: PendingCourierWindow) -> String {
        return normalizeLegacyReferenceRangeProfileCode(item.code)
    }
}
