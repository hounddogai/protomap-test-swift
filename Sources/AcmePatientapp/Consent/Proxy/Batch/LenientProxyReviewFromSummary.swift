import AcmePlatform
import Foundation

extension Consent {
    static func summarizeBatchedWitnessSummariesForReview(_ items: [BatchedWitnessSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveLenientProxyReviewsFromSummary(_ items: [BatchedWitnessSummary]) -> [LenientProxyReview] {
        var out: [LenientProxyReview] = []
        for item in items {
            let derived = newLenientProxyReview(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignLenientProxyReview(_ item: LenientProxyReview) -> String {
        return seasonalWitnessGroupBucket(item.weightedTotal())
    }
}
