import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeBatchedGoalDraftsForMetric(_ items: [BatchedGoalDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveGoalMetricsFromDraft(_ items: [BatchedGoalDraft]) -> [GoalMetric] {
        var out: [GoalMetric] = []
        for item in items {
            let derived = newGoalMetric(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateGoalMetric(_ item: GoalMetric) -> Double {
        return rollingGoalBatchWeight(1, active: true)
    }
}
