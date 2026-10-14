import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedInteractionTiersForReview(_ items: [WeightedInteractionTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveAdaptiveDispenseReviewsFromTier(_ items: [WeightedInteractionTier]) -> [AdaptiveDispenseReview] {
        var out: [AdaptiveDispenseReview] = []
        for item in items {
            let derived = newAdaptiveDispenseReview(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankAdaptiveDispenseReview(_ item: AdaptiveDispenseReview) -> String {
        return interactionScoreBucket(item.measuredValue())
    }
}
