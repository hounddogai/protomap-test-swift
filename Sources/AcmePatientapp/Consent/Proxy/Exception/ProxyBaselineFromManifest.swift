import AcmePlatform
import Foundation

extension Consent {
    static func summarizeTieredRevocationManifestsForBaseline(_ items: [TieredRevocationManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveProxyBaselinesFromManifest(_ items: [TieredRevocationManifest]) -> [ProxyBaseline] {
        var out: [ProxyBaseline] = []
        for item in items {
            let derived = newProxyBaseline(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveProxyBaseline(_ item: ProxyBaseline) -> String {
        return normalizeGlobalRevocationGroupCode(item.code)
    }
}
