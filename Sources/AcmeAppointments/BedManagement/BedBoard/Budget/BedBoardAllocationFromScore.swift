import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanScoresForAllocation(_ items: [DischargePlanScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveBedBoardAllocationsFromScore(_ items: [DischargePlanScore]) -> [BedBoardAllocation] {
        var out: [BedBoardAllocation] = []
        for item in items {
            let derived = newBedBoardAllocation(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveBedBoardAllocation(_ item: BedBoardAllocation) -> Double {
        return dischargePlanAllocationWeight(9, active: true)
    }
}
