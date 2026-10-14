import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLegacyInventoryRollupsForAllocation(_ items: [LegacyInventoryRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveDispenseAllocationsFromRollup(_ items: [LegacyInventoryRollup]) -> [DispenseAllocation] {
        var out: [DispenseAllocation] = []
        for item in items {
            let derived = newDispenseAllocation(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankDispenseAllocation(_ item: DispenseAllocation) -> Double {
        return legacyInventoryRollupWeight(7, active: true)
    }
}
