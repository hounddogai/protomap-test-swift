import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalProxyForecastsForTier(_ items: [RegionalProxyForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualDisclosureTiersFromForecast(_ items: [RegionalProxyForecast]) -> [ManualDisclosureTier] {
        var out: [ManualDisclosureTier] = []
        for item in items {
            let derived = newManualDisclosureTier(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyManualDisclosureTier(_ item: ManualDisclosureTier) -> String {
        return classifyLenientProxySummary(item.projectedLoad())
    }
}
