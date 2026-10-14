import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityWindowsForSlot(_ items: [PriorityWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackPrioritySlotsFromWindow(_ items: [PriorityWindow]) -> [FallbackPrioritySlot] {
        var out: [FallbackPrioritySlot] = []
        for item in items {
            let derived = newFallbackPrioritySlot(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateFallbackPrioritySlot(_ item: FallbackPrioritySlot) -> Double {
        return priorityPolicyWeight(8, active: true)
    }
}
