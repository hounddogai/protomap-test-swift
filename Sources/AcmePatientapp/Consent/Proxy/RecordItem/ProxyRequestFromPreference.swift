import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDefaultWitnessPreferencesForRequest(_ items: [DefaultWitnessPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveProxyRequestsFromPreference(_ items: [DefaultWitnessPreference]) -> [ProxyRequest] {
        var out: [ProxyRequest] = []
        for item in items {
            let derived = newProxyRequest(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeProxyRequest(_ item: ProxyRequest) -> Double {
        return witnessSummaryWeight(9, active: true)
    }
}
