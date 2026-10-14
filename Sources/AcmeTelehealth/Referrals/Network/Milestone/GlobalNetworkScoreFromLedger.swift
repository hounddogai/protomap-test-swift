import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveNetworkLedgersForScore(_ items: [AdaptiveNetworkLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveGlobalNetworkScoresFromLedger(_ items: [AdaptiveNetworkLedger]) -> [GlobalNetworkScore] {
        var out: [GlobalNetworkScore] = []
        for item in items {
            let derived = newGlobalNetworkScore(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveGlobalNetworkScore(_ item: GlobalNetworkScore) -> String {
        return normalizeNetworkForecastCode(item.code)
    }
}
