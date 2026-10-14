import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedRiskScoreManifestsForTemplate(_ items: [WeightedRiskScoreManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveBatchedGoalTemplatesFromManifest(_ items: [WeightedRiskScoreManifest]) -> [BatchedGoalTemplate] {
        var out: [BatchedGoalTemplate] = []
        for item in items {
            let derived = newBatchedGoalTemplate(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateBatchedGoalTemplate(_ item: BatchedGoalTemplate) -> String {
        return classifyWeightedRiskScoreManifest(item.weightedExposure())
    }
}
