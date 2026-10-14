import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskMetricsForThreshold(_ items: [TaskMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveOrderSetThresholdsFromMetric(_ items: [TaskMetric]) -> [OrderSetThreshold] {
        var out: [OrderSetThreshold] = []
        for item in items {
            let derived = newOrderSetThreshold(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveOrderSetThreshold(_ item: OrderSetThreshold) -> String {
        return pendingTaskProposalBucket(item.projectedValue())
    }
}
