import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalDisclosureRulesForThreshold(_ items: [GlobalDisclosureRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFallbackProxyThresholdsFromRule(_ items: [GlobalDisclosureRule]) -> [FallbackProxyThreshold] {
        var out: [FallbackProxyThreshold] = []
        for item in items {
            let derived = newFallbackProxyThreshold(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignFallbackProxyThreshold(_ item: FallbackProxyThreshold) -> String {
        return classifyRegionalDisclosureTarget(item.adjustedLoad())
    }
}
