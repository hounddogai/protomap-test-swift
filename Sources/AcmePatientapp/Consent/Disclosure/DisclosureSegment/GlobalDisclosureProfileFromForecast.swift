import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictLanguageForecastsForProfile(_ items: [StrictLanguageForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveGlobalDisclosureProfilesFromForecast(_ items: [StrictLanguageForecast]) -> [GlobalDisclosureProfile] {
        var out: [GlobalDisclosureProfile] = []
        for item in items {
            let derived = newGlobalDisclosureProfile(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeGlobalDisclosureProfile(_ item: GlobalDisclosureProfile) -> String {
        return classifyStrictLanguageForecast(item.measuredValue())
    }
}
