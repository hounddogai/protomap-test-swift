import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredReadVariancesForReview(_ items: [TieredReadVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePrimaryStudyReviewsFromVariance(_ items: [TieredReadVariance]) -> [PrimaryStudyReview] {
        var out: [PrimaryStudyReview] = []
        for item in items {
            let derived = newPrimaryStudyReview(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scorePrimaryStudyReview(_ item: PrimaryStudyReview) -> String {
        return strictReadSlotBucket(item.weightedTotal())
    }
}
