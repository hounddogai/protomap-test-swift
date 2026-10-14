import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeTieredSubstitutionOverridesForManifest(_ items: [TieredSubstitutionOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFallbackDispenseManifestsFromOverride(_ items: [TieredSubstitutionOverride]) -> [FallbackDispenseManifest] {
        var out: [FallbackDispenseManifest] = []
        for item in items {
            let derived = newFallbackDispenseManifest(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchFallbackDispenseManifest(_ item: FallbackDispenseManifest) -> String {
        return classifyRollingSubstitutionClaim(item.adjustedLoad())
    }
}
