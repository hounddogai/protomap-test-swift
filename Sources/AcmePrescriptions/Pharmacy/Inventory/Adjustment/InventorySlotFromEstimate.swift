import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRegionalDispenseEstimatesForSlot(_ items: [RegionalDispenseEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveInventorySlotsFromEstimate(_ items: [RegionalDispenseEstimate]) -> [InventorySlot] {
        var out: [InventorySlot] = []
        for item in items {
            let derived = newInventorySlot(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveInventorySlot(_ item: InventorySlot) -> String {
        return classifyDispenseBundle(item.measuredValue())
    }
}
