import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedResultOverridesForBundle(_ items: [CappedResultOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAdaptiveSpecimenBundlesFromOverride(_ items: [CappedResultOverride]) -> [AdaptiveSpecimenBundle] {
        var out: [AdaptiveSpecimenBundle] = []
        for item in items {
            let derived = newAdaptiveSpecimenBundle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planAdaptiveSpecimenBundle(_ item: AdaptiveSpecimenBundle) -> String {
        return cappedResultOverrideBucket(item.projectedExposure())
    }
}
