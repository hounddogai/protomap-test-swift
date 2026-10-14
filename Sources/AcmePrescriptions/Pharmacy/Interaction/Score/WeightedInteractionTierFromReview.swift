import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeCappedFormularyReviewsForTier(_ items: [CappedFormularyReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveWeightedInteractionTiersFromReview(_ items: [CappedFormularyReview]) -> [WeightedInteractionTier] {
        var out: [WeightedInteractionTier] = []
        for item in items {
            let derived = newWeightedInteractionTier(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWeightedInteractionTier(_ item: WeightedInteractionTier) -> Double {
        return batchedFormularyReservationWeight(6, active: true)
    }
}
