import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessRulesForManifest(_ items: [WitnessRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveRollingWitnessManifestsFromRule(_ items: [WitnessRule]) -> [RollingWitnessManifest] {
        var out: [RollingWitnessManifest] = []
        for item in items {
            let derived = newRollingWitnessManifest(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyRollingWitnessManifest(_ item: RollingWitnessManifest) -> String {
        return witnessQuotaBucket(item.adjustedLoad())
    }
}
