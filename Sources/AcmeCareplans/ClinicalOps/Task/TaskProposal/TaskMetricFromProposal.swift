import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackHandoffProposalsForMetric(_ items: [FallbackHandoffProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveTaskMetricsFromProposal(_ items: [FallbackHandoffProposal]) -> [TaskMetric] {
        var out: [TaskMetric] = []
        for item in items {
            let derived = newTaskMetric(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeTaskMetric(_ item: TaskMetric) -> String {
        return classifyTieredHandoffLedger(item.effectiveLoad())
    }
}
