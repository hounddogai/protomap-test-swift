import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureCheckpointsForTier(_ items: [DisclosureCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveProxyTiersFromCheckpoint(_ items: [DisclosureCheckpoint]) -> [ProxyTier] {
        var out: [ProxyTier] = []
        for item in items {
            let derived = newProxyTier(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankProxyTier(_ item: ProxyTier) -> Double {
        return disclosureCheckpointWeight(8, active: true)
    }
}
