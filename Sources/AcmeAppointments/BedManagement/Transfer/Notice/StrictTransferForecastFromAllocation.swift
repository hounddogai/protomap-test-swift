import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBatchedBedBoardAllocationsForForecast(_ items: [BatchedBedBoardAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictTransferForecastsFromAllocation(_ items: [BatchedBedBoardAllocation]) -> [StrictTransferForecast] {
        var out: [StrictTransferForecast] = []
        for item in items {
            let derived = newStrictTransferForecast(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateStrictTransferForecast(_ item: StrictTransferForecast) -> String {
        return classifyBatchedBedBoardAllocation(item.weightedLoad())
    }
}
