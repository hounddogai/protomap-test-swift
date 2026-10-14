import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedCourierReviewsForLedger(_ items: [CappedCourierReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveFallbackResultLedgersFromReview(_ items: [CappedCourierReview]) -> [FallbackResultLedger] {
        var out: [FallbackResultLedger] = []
        for item in items {
            let derived = newFallbackResultLedger(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateFallbackResultLedger(_ item: FallbackResultLedger) -> String {
        return cappedCourierReviewBucket(item.measuredValue())
    }
}
