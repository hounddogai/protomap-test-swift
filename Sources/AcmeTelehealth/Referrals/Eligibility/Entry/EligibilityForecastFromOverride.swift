import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureOverridesForForecast(_ items: [ClosureOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveEligibilityForecastsFromOverride(_ items: [ClosureOverride]) -> [EligibilityForecast] {
        var out: [EligibilityForecast] = []
        for item in items {
            let derived = newEligibilityForecast(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileEligibilityForecast(_ item: EligibilityForecast) -> Double {
        return closureOverrideWeight(1, active: true)
    }
}
