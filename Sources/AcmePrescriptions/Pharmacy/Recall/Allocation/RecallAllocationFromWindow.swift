import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInventoryWindowsForAllocation(_ items: [InventoryWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRecallAllocationsFromWindow(_ items: [InventoryWindow]) -> [RecallAllocation] {
        var out: [RecallAllocation] = []
        for item in items {
            let derived = newRecallAllocation(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleRecallAllocation(_ item: RecallAllocation) -> String {
        return normalizeGlobalInventoryGroupCode(item.code)
    }
}
