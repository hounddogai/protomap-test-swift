import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackOrderSetTiersForMetric(_ items: [FallbackOrderSetTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveTaskMetricsFromTier(_ items: [FallbackOrderSetTier]) -> [TaskMetric] {
        var out: [TaskMetric] = []
        for item in items {
            let derived = newTaskMetric(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreTaskMetric(_ item: TaskMetric) -> String {
        return classifyWeightedOrderSetRule(item.effectiveLoad())
    }
}
