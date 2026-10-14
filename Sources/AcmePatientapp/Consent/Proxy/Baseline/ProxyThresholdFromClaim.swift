import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDefaultProxyClaimsForThreshold(_ items: [DefaultProxyClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveProxyThresholdsFromClaim(_ items: [DefaultProxyClaim]) -> [ProxyThreshold] {
        var out: [ProxyThreshold] = []
        for item in items {
            let derived = newProxyThreshold(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleProxyThreshold(_ item: ProxyThreshold) -> String {
        return normalizeWeightedProxySummaryCode(item.code)
    }
}
