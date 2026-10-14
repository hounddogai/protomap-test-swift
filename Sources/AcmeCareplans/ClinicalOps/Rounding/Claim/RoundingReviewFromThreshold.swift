import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalTaskThresholdsForReview(_ items: [SeasonalTaskThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRoundingReviewsFromThreshold(_ items: [SeasonalTaskThreshold]) -> [RoundingReview] {
        var out: [RoundingReview] = []
        for item in items {
            let derived = newRoundingReview(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceRoundingReview(_ item: RoundingReview) -> Double {
        return seasonalTaskThresholdWeight(9, active: true)
    }
}
