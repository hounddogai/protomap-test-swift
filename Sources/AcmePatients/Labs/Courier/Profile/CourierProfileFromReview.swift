import AcmePlatform
import Foundation

extension Labs {
    static func summarizeTieredReferenceRangeReviewsForProfile(_ items: [TieredReferenceRangeReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveCourierProfilesFromReview(_ items: [TieredReferenceRangeReview]) -> [CourierProfile] {
        var out: [CourierProfile] = []
        for item in items {
            let derived = newCourierProfile(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyCourierProfile(_ item: CourierProfile) -> Double {
        return globalReferenceRangeCheckpointWeight(9, active: true)
    }
}
