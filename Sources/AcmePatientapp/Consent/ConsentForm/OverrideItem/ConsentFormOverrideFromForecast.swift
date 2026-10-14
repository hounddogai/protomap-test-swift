import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalDisclosureForecastsForOverride(_ items: [GlobalDisclosureForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveConsentFormOverridesFromForecast(_ items: [GlobalDisclosureForecast]) -> [ConsentFormOverride] {
        var out: [ConsentFormOverride] = []
        for item in items {
            let derived = newConsentFormOverride(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceConsentFormOverride(_ item: ConsentFormOverride) -> String {
        return normalizeGlobalDisclosureForecastCode(item.code)
    }
}
