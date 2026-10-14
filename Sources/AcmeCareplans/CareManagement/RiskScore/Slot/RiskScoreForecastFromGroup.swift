import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeFallbackGoalGroupsForForecast(_ items: [FallbackGoalGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRiskScoreForecastsFromGroup(_ items: [FallbackGoalGroup]) -> [RiskScoreForecast] {
        var out: [RiskScoreForecast] = []
        for item in items {
            let derived = newRiskScoreForecast(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeRiskScoreForecast(_ item: RiskScoreForecast) -> String {
        return normalizeFallbackGoalGroupCode(item.code)
    }
}
