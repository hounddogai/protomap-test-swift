import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackTransferMetricsForPreference(_ items: [FallbackTransferMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveWeightedBedBoardPreferencesFromMetric(_ items: [FallbackTransferMetric]) -> [WeightedBedBoardPreference] {
        var out: [WeightedBedBoardPreference] = []
        for item in items {
            let derived = newWeightedBedBoardPreference(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveWeightedBedBoardPreference(_ item: WeightedBedBoardPreference) -> String {
        return pendingTransferSummaryBucket(item.projectedValue())
    }
}
