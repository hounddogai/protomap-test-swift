import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLenientDispenseRequestsForWindow(_ items: [LenientDispenseRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveScheduledInventoryWindowsFromRequest(_ items: [LenientDispenseRequest]) -> [ScheduledInventoryWindow] {
        var out: [ScheduledInventoryWindow] = []
        for item in items {
            let derived = newScheduledInventoryWindow(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyScheduledInventoryWindow(_ item: ScheduledInventoryWindow) -> Double {
        return scheduledDispenseMetricWeight(9, active: true)
    }
}
