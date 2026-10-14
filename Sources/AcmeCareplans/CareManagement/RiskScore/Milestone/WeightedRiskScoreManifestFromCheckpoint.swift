import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalCheckpointsForManifest(_ items: [GoalCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedRiskScoreManifestsFromCheckpoint(_ items: [GoalCheckpoint]) -> [WeightedRiskScoreManifest] {
        var out: [WeightedRiskScoreManifest] = []
        for item in items {
            let derived = newWeightedRiskScoreManifest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeWeightedRiskScoreManifest(_ item: WeightedRiskScoreManifest) -> String {
        return classifyLenientGoalVariance(item.adjustedValue())
    }
}
