import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardReservationsForAllocation(_ items: [BedBoardReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualCensusAllocationsFromReservation(_ items: [BedBoardReservation]) -> [ManualCensusAllocation] {
        var out: [ManualCensusAllocation] = []
        for item in items {
            let derived = newManualCensusAllocation(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeManualCensusAllocation(_ item: ManualCensusAllocation) -> String {
        return regionalBedBoardAllocationBucket(item.effectiveTotal())
    }
}
