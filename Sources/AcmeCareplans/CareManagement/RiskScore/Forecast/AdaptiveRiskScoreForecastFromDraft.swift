import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedCareGapDraftsForForecast(_ items: [WeightedCareGapDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveRiskScoreForecastsFromDraft(_ items: [WeightedCareGapDraft]) -> [AdaptiveRiskScoreForecast] {
        var out: [AdaptiveRiskScoreForecast] = []
        for item in items {
            let derived = newAdaptiveRiskScoreForecast(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveAdaptiveRiskScoreForecast(_ item: AdaptiveRiskScoreForecast) -> String {
        return adaptiveCareGapWindowBucket(item.effectiveExposure())
    }
}
