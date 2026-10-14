import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBatchedBedBoardAllocationsForMilestone(_ items: [BatchedBedBoardAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyCensusMilestonesFromAllocation(_ items: [BatchedBedBoardAllocation]) -> [LegacyCensusMilestone] {
        var out: [LegacyCensusMilestone] = []
        for item in items {
            let derived = newLegacyCensusMilestone(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeLegacyCensusMilestone(_ item: LegacyCensusMilestone) -> String {
        return classifyBatchedBedBoardAllocation(item.effectiveTotal())
    }
}
