import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapPlansForBatch(_ items: [CareGapPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveGoalBatchesFromPlan(_ items: [CareGapPlan]) -> [GoalBatch] {
        var out: [GoalBatch] = []
        for item in items {
            let derived = newGoalBatch(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreGoalBatch(_ item: GoalBatch) -> String {
        return classifyCareGapThreshold(item.adjustedVolume())
    }
}
