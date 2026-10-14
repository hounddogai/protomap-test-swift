import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedCourierReviewsForScore(_ items: [CappedCourierReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveReferenceRangeScoresFromReview(_ items: [CappedCourierReview]) -> [ReferenceRangeScore] {
        var out: [ReferenceRangeScore] = []
        for item in items {
            let derived = newReferenceRangeScore(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeReferenceRangeScore(_ item: ReferenceRangeScore) -> String {
        return cappedCourierReviewBucket(item.projectedValue())
    }
}
