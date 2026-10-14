import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierOverridesForReview(_ items: [CourierOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveCappedCourierReviewsFromOverride(_ items: [CourierOverride]) -> [CappedCourierReview] {
        var out: [CappedCourierReview] = []
        for item in items {
            let derived = newCappedCourierReview(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCappedCourierReview(_ item: CappedCourierReview) -> String {
        return courierManifestBucket(item.weightedValue())
    }
}
