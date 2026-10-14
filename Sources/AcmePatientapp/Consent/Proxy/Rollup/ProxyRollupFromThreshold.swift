import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationThresholdsForRollup(_ items: [RevocationThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveProxyRollupsFromThreshold(_ items: [RevocationThreshold]) -> [ProxyRollup] {
        var out: [ProxyRollup] = []
        for item in items {
            let derived = newProxyRollup(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceProxyRollup(_ item: ProxyRollup) -> String {
        return classifyRevocationThreshold(item.adjustedLoad())
    }
}
