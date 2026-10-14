import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedDispenseMetricsForAdjustment(_ items: [WeightedDispenseMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRecallAdjustmentsFromMetric(_ items: [WeightedDispenseMetric]) -> [RecallAdjustment] {
        var out: [RecallAdjustment] = []
        for item in items {
            let derived = newRecallAdjustment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRecallAdjustment(_ item: RecallAdjustment) -> String {
        return normalizeWeightedDispenseMetricCode(item.code)
    }
}
