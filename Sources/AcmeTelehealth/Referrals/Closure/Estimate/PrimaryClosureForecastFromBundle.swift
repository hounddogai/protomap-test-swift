import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultNetworkBundlesForForecast(_ items: [DefaultNetworkBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func derivePrimaryClosureForecastsFromBundle(_ items: [DefaultNetworkBundle]) -> [PrimaryClosureForecast] {
        var out: [PrimaryClosureForecast] = []
        for item in items {
            let derived = newPrimaryClosureForecast(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyPrimaryClosureForecast(_ item: PrimaryClosureForecast) -> String {
        return pendingNetworkThresholdBucket(item.netValue())
    }
}
