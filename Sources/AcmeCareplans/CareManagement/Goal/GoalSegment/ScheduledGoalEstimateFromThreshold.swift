import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAdaptiveAssessmentThresholdsForEstimate(_ items: [AdaptiveAssessmentThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveScheduledGoalEstimatesFromThreshold(_ items: [AdaptiveAssessmentThreshold]) -> [ScheduledGoalEstimate] {
        var out: [ScheduledGoalEstimate] = []
        for item in items {
            let derived = newScheduledGoalEstimate(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitScheduledGoalEstimate(_ item: ScheduledGoalEstimate) -> Double {
        return regionalAssessmentEstimateWeight(7, active: true)
    }
}
