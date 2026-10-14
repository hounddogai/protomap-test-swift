import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeFallbackAssessmentAllocationsForCheckpoint(_ items: [FallbackAssessmentAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveAdaptiveRiskScoreCheckpointsFromAllocation(_ items: [FallbackAssessmentAllocation]) -> [AdaptiveRiskScoreCheckpoint] {
        var out: [AdaptiveRiskScoreCheckpoint] = []
        for item in items {
            let derived = newAdaptiveRiskScoreCheckpoint(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateAdaptiveRiskScoreCheckpoint(_ item: AdaptiveRiskScoreCheckpoint) -> Double {
        return assessmentSegmentWeight(1, active: true)
    }
}
