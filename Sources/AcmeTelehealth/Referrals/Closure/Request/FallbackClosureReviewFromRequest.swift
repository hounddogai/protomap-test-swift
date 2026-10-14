import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureRequestsForReview(_ items: [ClosureRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveFallbackClosureReviewsFromRequest(_ items: [ClosureRequest]) -> [FallbackClosureReview] {
        var out: [FallbackClosureReview] = []
        for item in items {
            let derived = newFallbackClosureReview(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceFallbackClosureReview(_ item: FallbackClosureReview) -> String {
        return closureRequestBucket(item.weightedLoad())
    }
}
