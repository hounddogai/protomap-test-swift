import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRegionalAssessmentEstimatesForCheckpoint(_ items: [RegionalAssessmentEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveFallbackRiskScoreCheckpointsFromEstimate(_ items: [RegionalAssessmentEstimate]) -> [FallbackRiskScoreCheckpoint] {
        var out: [FallbackRiskScoreCheckpoint] = []
        for item in items {
            let derived = newFallbackRiskScoreCheckpoint(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planFallbackRiskScoreCheckpoint(_ item: FallbackRiskScoreCheckpoint) -> String {
        return adaptiveAssessmentThresholdBucket(item.measuredValue())
    }
}
