import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedReferralDraftsForBaseline(_ items: [WeightedReferralDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveWeightedClosureBaselinesFromDraft(_ items: [WeightedReferralDraft]) -> [WeightedClosureBaseline] {
        var out: [WeightedClosureBaseline] = []
        for item in items {
            let derived = newWeightedClosureBaseline(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyWeightedClosureBaseline(_ item: WeightedClosureBaseline) -> String {
        return weightedReferralDraftBucket(item.measuredValue())
    }
}
