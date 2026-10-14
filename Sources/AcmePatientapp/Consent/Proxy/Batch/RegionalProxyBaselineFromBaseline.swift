import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictProxyBaselinesForBaseline(_ items: [StrictProxyBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveRegionalProxyBaselinesFromBaseline(_ items: [StrictProxyBaseline]) -> [RegionalProxyBaseline] {
        var out: [RegionalProxyBaseline] = []
        for item in items {
            let derived = newRegionalProxyBaseline(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyRegionalProxyBaselineExtra(_ item: RegionalProxyBaseline) -> Double {
        return proxyReservationWeight(4, active: true)
    }
}
