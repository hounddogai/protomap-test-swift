import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredNetworkEntriesForForecast(_ items: [TieredNetworkEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveNetworkForecastsFromEntry(_ items: [TieredNetworkEntry]) -> [NetworkForecast] {
        var out: [NetworkForecast] = []
        for item in items {
            let derived = newNetworkForecast(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planNetworkForecast(_ item: NetworkForecast) -> String {
        return classifyNetworkRequest(item.netLoad())
    }
}
