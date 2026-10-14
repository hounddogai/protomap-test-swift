import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedDispenseMetricsForBundle(_ items: [WeightedDispenseMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveBatchedFormularyBundlesFromMetric(_ items: [WeightedDispenseMetric]) -> [BatchedFormularyBundle] {
        var out: [BatchedFormularyBundle] = []
        for item in items {
            let derived = newBatchedFormularyBundle(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeBatchedFormularyBundle(_ item: BatchedFormularyBundle) -> String {
        return normalizeWeightedDispenseMetricCode(item.code)
    }
}
