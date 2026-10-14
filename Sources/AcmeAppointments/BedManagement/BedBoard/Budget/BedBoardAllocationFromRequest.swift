import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationRequestsForAllocation(_ items: [IsolationRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveBedBoardAllocationsFromRequest(_ items: [IsolationRequest]) -> [BedBoardAllocation] {
        var out: [BedBoardAllocation] = []
        for item in items {
            let derived = newBedBoardAllocation(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleBedBoardAllocation(_ item: BedBoardAllocation) -> String {
        return classifyIsolationSchedule(item.measuredValue())
    }
}
