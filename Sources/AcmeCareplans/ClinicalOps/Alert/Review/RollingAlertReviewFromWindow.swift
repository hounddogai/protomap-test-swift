import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingRoundingWindowsForReview(_ items: [PendingRoundingWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRollingAlertReviewsFromWindow(_ items: [PendingRoundingWindow]) -> [RollingAlertReview] {
        var out: [RollingAlertReview] = []
        for item in items {
            let derived = newRollingAlertReview(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateRollingAlertReview(_ item: RollingAlertReview) -> String {
        return tieredRoundingAdjustmentBucket(item.projectedExposure())
    }
}
