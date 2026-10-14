import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessForecastsForCycle(_ items: [WitnessForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveLanguageCyclesFromForecast(_ items: [WitnessForecast]) -> [LanguageCycle] {
        var out: [LanguageCycle] = []
        for item in items {
            let derived = newLanguageCycle(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitLanguageCycle(_ item: LanguageCycle) -> String {
        return classifyWitnessPreference(item.projectedLoad())
    }
}
