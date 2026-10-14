import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalModalityClaimsForReview(_ items: [RegionalModalityClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveFallbackWorklistReviewsFromClaim(_ items: [RegionalModalityClaim]) -> [FallbackWorklistReview] {
        var out: [FallbackWorklistReview] = []
        for item in items {
            let derived = newFallbackWorklistReview(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchFallbackWorklistReview(_ item: FallbackWorklistReview) -> String {
        return strictModalityTargetBucket(item.projectedVolume())
    }
}
