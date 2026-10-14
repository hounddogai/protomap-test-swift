import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAdaptiveRiskScoreForecastsForThreshold(_ items: [AdaptiveRiskScoreForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveWeightedAssessmentThresholdsFromForecast(_ items: [AdaptiveRiskScoreForecast]) -> [WeightedAssessmentThreshold] {
        var out: [WeightedAssessmentThreshold] = []
        for item in items {
            let derived = newWeightedAssessmentThreshold(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectWeightedAssessmentThreshold(_ item: WeightedAssessmentThreshold) -> String {
        return normalizeCappedRiskScoreWindowCode(item.code)
    }
}
