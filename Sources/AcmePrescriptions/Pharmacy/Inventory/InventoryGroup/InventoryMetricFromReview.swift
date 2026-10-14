import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeAdaptiveRecallReviewsForMetric(_ items: [AdaptiveRecallReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveInventoryMetricsFromReview(_ items: [AdaptiveRecallReview]) -> [InventoryMetric] {
        var out: [InventoryMetric] = []
        for item in items {
            let derived = newInventoryMetric(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyInventoryMetricExtra(_ item: InventoryMetric) -> String {
        return normalizeRecallMetricCode(item.code)
    }
}
