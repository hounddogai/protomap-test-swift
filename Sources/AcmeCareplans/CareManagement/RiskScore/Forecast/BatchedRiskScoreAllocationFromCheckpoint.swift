import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAdaptiveRiskScoreCheckpointsForAllocation(_ items: [AdaptiveRiskScoreCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveBatchedRiskScoreAllocationsFromCheckpoint(_ items: [AdaptiveRiskScoreCheckpoint]) -> [BatchedRiskScoreAllocation] {
        var out: [BatchedRiskScoreAllocation] = []
        for item in items {
            let derived = newBatchedRiskScoreAllocation(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedRiskScoreAllocation(_ item: BatchedRiskScoreAllocation) -> Double {
        return adaptiveRiskScoreCheckpointWeight(5, active: true)
    }
}
