import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferSchedulesForAllocation(_ items: [TransferSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveBatchedBedBoardAllocationsFromSchedule(_ items: [TransferSchedule]) -> [BatchedBedBoardAllocation] {
        var out: [BatchedBedBoardAllocation] = []
        for item in items {
            let derived = newBatchedBedBoardAllocation(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedBedBoardAllocation(_ item: BatchedBedBoardAllocation) -> String {
        return transferScheduleBucket(item.measuredValue())
    }
}
