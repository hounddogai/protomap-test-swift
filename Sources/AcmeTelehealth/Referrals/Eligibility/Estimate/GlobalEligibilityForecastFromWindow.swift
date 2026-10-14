import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultNetworkWindowsForForecast(_ items: [DefaultNetworkWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveGlobalEligibilityForecastsFromWindow(_ items: [DefaultNetworkWindow]) -> [GlobalEligibilityForecast] {
        var out: [GlobalEligibilityForecast] = []
        for item in items {
            let derived = newGlobalEligibilityForecast(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectGlobalEligibilityForecast(_ item: GlobalEligibilityForecast) -> String {
        return classifyRegionalNetworkRule(item.netTotal())
    }
}
