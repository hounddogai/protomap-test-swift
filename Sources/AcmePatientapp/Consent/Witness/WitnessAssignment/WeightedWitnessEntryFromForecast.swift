import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictLanguageForecastsForEntry(_ items: [StrictLanguageForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveWeightedWitnessEntriesFromForecast(_ items: [StrictLanguageForecast]) -> [WeightedWitnessEntry] {
        var out: [WeightedWitnessEntry] = []
        for item in items {
            let derived = newWeightedWitnessEntry(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignWeightedWitnessEntry(_ item: WeightedWitnessEntry) -> String {
        return classifyWeightedLanguageTier(item.effectiveVolume())
    }
}
