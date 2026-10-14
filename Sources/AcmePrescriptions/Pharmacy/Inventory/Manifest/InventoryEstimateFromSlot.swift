import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacyRecallSlotsForEstimate(_ items: [LegacyRecallSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveInventoryEstimatesFromSlot(_ items: [LegacyRecallSlot]) -> [InventoryEstimate] {
        var out: [InventoryEstimate] = []
        for item in items {
            let derived = newInventoryEstimate(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchInventoryEstimate(_ item: InventoryEstimate) -> String {
        return recallBundleBucket(item.effectiveLoad())
    }
}
