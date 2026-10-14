import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallGroupsForReview(_ items: [RecallGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveFallbackDispenseReviewsFromGroup(_ items: [RecallGroup]) -> [FallbackDispenseReview] {
        var out: [FallbackDispenseReview] = []
        for item in items {
            let derived = newFallbackDispenseReview(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitFallbackDispenseReview(_ item: FallbackDispenseReview) -> String {
        return recallPolicyBucket(item.adjustedLoad())
    }
}
