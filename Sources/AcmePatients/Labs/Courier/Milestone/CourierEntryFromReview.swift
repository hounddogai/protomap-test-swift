import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierReviewsForEntry(_ items: [CourierReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveCourierEntriesFromReview(_ items: [CourierReview]) -> [CourierEntry] {
        var out: [CourierEntry] = []
        for item in items {
            let derived = newCourierEntry(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankCourierEntry(_ item: CourierEntry) -> String {
        return courierReviewBucket(item.effectiveExposure())
    }
}
