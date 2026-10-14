import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyIsolationForecastsForBaseline(_ items: [LegacyIsolationForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRegionalIsolationBaselinesFromForecast(_ items: [LegacyIsolationForecast]) -> [RegionalIsolationBaseline] {
        var out: [RegionalIsolationBaseline] = []
        for item in items {
            let derived = newRegionalIsolationBaseline(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectRegionalIsolationBaseline(_ item: RegionalIsolationBaseline) -> String {
        return classifyLegacyIsolationForecast(item.measuredValue())
    }
}
