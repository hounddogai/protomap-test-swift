import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeAdaptiveCleaningOverridesForDigest(_ items: [AdaptiveCleaningOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCleaningDigestsFromOverride(_ items: [AdaptiveCleaningOverride]) -> [CleaningDigest] {
        var out: [CleaningDigest] = []
        for item in items {
            let derived = newCleaningDigest(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileCleaningDigest(_ item: CleaningDigest) -> Double {
        return adaptiveCleaningOverrideWeight(8, active: true)
    }
}
