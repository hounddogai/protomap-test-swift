import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedAssessmentThresholdsForOverride(_ items: [WeightedAssessmentThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryCareGapOverridesFromThreshold(_ items: [WeightedAssessmentThreshold]) -> [PrimaryCareGapOverride] {
        var out: [PrimaryCareGapOverride] = []
        for item in items {
            let derived = newPrimaryCareGapOverride(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizePrimaryCareGapOverride(_ item: PrimaryCareGapOverride) -> Double {
        return weightedAssessmentThresholdWeight(6, active: true)
    }
}
