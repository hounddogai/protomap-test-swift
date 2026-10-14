import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWeightedWitnessForecastsForVariance(_ items: [WeightedWitnessForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveConsentFormVariancesFromForecast(_ items: [WeightedWitnessForecast]) -> [ConsentFormVariance] {
        var out: [ConsentFormVariance] = []
        for item in items {
            let derived = newConsentFormVariance(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchConsentFormVariance(_ item: ConsentFormVariance) -> String {
        return witnessMilestoneBucket(item.effectiveLoad())
    }
}
