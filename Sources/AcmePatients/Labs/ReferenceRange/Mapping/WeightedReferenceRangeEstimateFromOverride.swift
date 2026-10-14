import AcmePlatform
import Foundation

extension Labs {
    static func summarizeManualSpecimenOverridesForEstimate(_ items: [ManualSpecimenOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveWeightedReferenceRangeEstimatesFromOverride(_ items: [ManualSpecimenOverride]) -> [WeightedReferenceRangeEstimate] {
        var out: [WeightedReferenceRangeEstimate] = []
        for item in items {
            let derived = newWeightedReferenceRangeEstimate(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreWeightedReferenceRangeEstimate(_ item: WeightedReferenceRangeEstimate) -> String {
        return classifySpecimenManifest(item.netVolume())
    }
}
