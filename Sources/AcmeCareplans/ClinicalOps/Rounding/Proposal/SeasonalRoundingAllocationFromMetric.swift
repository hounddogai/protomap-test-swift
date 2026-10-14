import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeBatchedRoundingMetricsForAllocation(_ items: [BatchedRoundingMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalRoundingAllocationsFromMetric(_ items: [BatchedRoundingMetric]) -> [SeasonalRoundingAllocation] {
        var out: [SeasonalRoundingAllocation] = []
        for item in items {
            let derived = newSeasonalRoundingAllocation(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreSeasonalRoundingAllocation(_ item: SeasonalRoundingAllocation) -> String {
        return classifyRoundingAgreement(item.measuredValue())
    }
}
