import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCappedCareGapAssignmentsForPlan(_ items: [CappedCareGapAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveBatchedGoalPlansFromAssignment(_ items: [CappedCareGapAssignment]) -> [BatchedGoalPlan] {
        var out: [BatchedGoalPlan] = []
        for item in items {
            let derived = newBatchedGoalPlan(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeBatchedGoalPlan(_ item: BatchedGoalPlan) -> String {
        return classifyCappedCareGapAssignment(item.adjustedExposure())
    }
}
