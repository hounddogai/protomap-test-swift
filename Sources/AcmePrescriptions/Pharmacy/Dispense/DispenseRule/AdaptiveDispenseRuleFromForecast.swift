import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRegionalSubstitutionForecastsForRule(_ items: [RegionalSubstitutionForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveAdaptiveDispenseRulesFromForecast(_ items: [RegionalSubstitutionForecast]) -> [AdaptiveDispenseRule] {
        var out: [AdaptiveDispenseRule] = []
        for item in items {
            let derived = newAdaptiveDispenseRule(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeAdaptiveDispenseRule(_ item: AdaptiveDispenseRule) -> String {
        return regionalSubstitutionForecastBucket(item.adjustedValue())
    }
}
