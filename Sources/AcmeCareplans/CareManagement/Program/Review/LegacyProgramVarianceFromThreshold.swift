import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedAssessmentThresholdsForVariance(_ items: [WeightedAssessmentThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyProgramVariancesFromThreshold(_ items: [WeightedAssessmentThreshold]) -> [LegacyProgramVariance] {
        var out: [LegacyProgramVariance] = []
        for item in items {
            let derived = newLegacyProgramVariance(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceLegacyProgramVariance(_ item: LegacyProgramVariance) -> Double {
        return pendingAssessmentSegmentWeight(9, active: true)
    }
}
