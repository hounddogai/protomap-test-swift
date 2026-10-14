import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalDisclosureBaselinesForForecast(_ items: [GlobalDisclosureBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalDisclosureForecastsFromBaseline(_ items: [GlobalDisclosureBaseline]) -> [GlobalDisclosureForecast] {
        var out: [GlobalDisclosureForecast] = []
        for item in items {
            let derived = newGlobalDisclosureForecast(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveGlobalDisclosureForecast(_ item: GlobalDisclosureForecast) -> String {
        return normalizeGlobalDisclosureBaselineCode(item.code)
    }
}
