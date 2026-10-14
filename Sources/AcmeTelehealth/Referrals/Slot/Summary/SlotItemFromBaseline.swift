import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureBaselinesForItem(_ items: [ClosureBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveSlotItemsFromBaseline(_ items: [ClosureBaseline]) -> [SlotItem] {
        var out: [SlotItem] = []
        for item in items {
            let derived = newSlotItem(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchSlotItem(_ item: SlotItem) -> Double {
        return closureBaselineWeight(1, active: true)
    }
}
