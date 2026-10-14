import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedGoalDigestsForPlan(_ items: [WeightedGoalDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveBatchedProgramPlansFromDigest(_ items: [WeightedGoalDigest]) -> [BatchedProgramPlan] {
        var out: [BatchedProgramPlan] = []
        for item in items {
            let derived = newBatchedProgramPlan(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planBatchedProgramPlan(_ item: BatchedProgramPlan) -> String {
        return tieredGoalForecastBucket(item.netVolume())
    }
}
