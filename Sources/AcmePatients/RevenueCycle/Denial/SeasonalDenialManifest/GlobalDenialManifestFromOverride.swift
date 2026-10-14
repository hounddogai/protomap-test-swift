import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceOverridesForManifest(_ items: [RemittanceOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveGlobalDenialManifestsFromOverride(_ items: [RemittanceOverride]) -> [GlobalDenialManifest] {
        var out: [GlobalDenialManifest] = []
        for item in items {
            let derived = newGlobalDenialManifest(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyGlobalDenialManifestExtra(_ item: GlobalDenialManifest) -> String {
        return classifyRemittanceOverride(item.projectedLoad())
    }
}
