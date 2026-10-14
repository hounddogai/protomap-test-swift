import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeAdaptiveCleaningProfilesForVariance(_ items: [AdaptiveCleaningProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedIsolationVariancesFromProfile(_ items: [AdaptiveCleaningProfile]) -> [WeightedIsolationVariance] {
        var out: [WeightedIsolationVariance] = []
        for item in items {
            let derived = newWeightedIsolationVariance(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitWeightedIsolationVariance(_ item: WeightedIsolationVariance) -> String {
        return normalizeAdaptiveCleaningProfileCode(item.code)
    }
}
