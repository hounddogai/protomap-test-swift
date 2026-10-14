import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientWorklistProfilesForReview(_ items: [LenientWorklistProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryStudyReviewsFromProfile(_ items: [LenientWorklistProfile]) -> [PrimaryStudyReview] {
        var out: [PrimaryStudyReview] = []
        for item in items {
            let derived = newPrimaryStudyReview(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignPrimaryStudyReview(_ item: PrimaryStudyReview) -> String {
        return rollingWorklistAdjustmentBucket(item.weightedTotal())
    }
}
