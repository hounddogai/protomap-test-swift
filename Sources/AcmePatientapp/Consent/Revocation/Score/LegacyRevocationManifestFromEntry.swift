import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingWitnessEntriesForManifest(_ items: [RollingWitnessEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLegacyRevocationManifestsFromEntry(_ items: [RollingWitnessEntry]) -> [LegacyRevocationManifest] {
        var out: [LegacyRevocationManifest] = []
        for item in items {
            let derived = newLegacyRevocationManifest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeLegacyRevocationManifest(_ item: LegacyRevocationManifest) -> String {
        return classifyRollingWitnessEntry(item.effectiveExposure())
    }
}
