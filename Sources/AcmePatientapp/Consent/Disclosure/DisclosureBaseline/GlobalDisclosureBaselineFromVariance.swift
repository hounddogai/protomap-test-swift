import AcmePlatform
import Foundation

extension Consent {
    static func summarizeProxyVariancesForBaseline(_ items: [ProxyVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveGlobalDisclosureBaselinesFromVariance(_ items: [ProxyVariance]) -> [GlobalDisclosureBaseline] {
        var out: [GlobalDisclosureBaseline] = []
        for item in items {
            let derived = newGlobalDisclosureBaseline(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitGlobalDisclosureBaseline(_ item: GlobalDisclosureBaseline) -> String {
        return proxyVarianceBucket(item.measuredValue())
    }
}
