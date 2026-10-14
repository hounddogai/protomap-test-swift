import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeGlobalChargeReviewsForSummary(_ items: [GlobalChargeReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictClaimSummariesFromReview(_ items: [GlobalChargeReview]) -> [StrictClaimSummary] {
        var out: [StrictClaimSummary] = []
        for item in items {
            let derived = newStrictClaimSummary(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitStrictClaimSummary(_ item: StrictClaimSummary) -> String {
        return globalChargeReviewBucket(item.adjustedTotal())
    }
}
