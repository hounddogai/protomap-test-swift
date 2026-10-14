import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryPlansForAllocation(_ items: [InventoryPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLegacyRecallAllocationsFromPlan(_ items: [InventoryPlan]) -> [LegacyRecallAllocation] {
        var out: [LegacyRecallAllocation] = []
        for item in items {
            let derived = newLegacyRecallAllocation(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreLegacyRecallAllocationExtra(_ item: LegacyRecallAllocation) -> Double {
        return inventoryPlanWeight(2, active: true)
    }
}
