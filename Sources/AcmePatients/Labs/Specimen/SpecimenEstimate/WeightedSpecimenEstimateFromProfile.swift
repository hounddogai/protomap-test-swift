import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackReferenceRangeProfilesForEstimate(_ items: [FallbackReferenceRangeProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveWeightedSpecimenEstimatesFromProfile(_ items: [FallbackReferenceRangeProfile]) -> [WeightedSpecimenEstimate] {
        var out: [WeightedSpecimenEstimate] = []
        for item in items {
            let derived = newWeightedSpecimenEstimate(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileWeightedSpecimenEstimate(_ item: WeightedSpecimenEstimate) -> String {
        return classifyFallbackReferenceRangeProfile(item.adjustedValue())
    }
}
