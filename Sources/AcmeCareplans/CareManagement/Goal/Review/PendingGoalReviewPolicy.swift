import AcmePlatform
import Foundation

extension CareManagement {
    static func pendingGoalReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a pending goal review score falls in.
    static func classifyPendingGoalReview(_ score: Double) -> String {
        if score < 9.0 {
            return "low"
        }
        if score < 66.9 {
            return "ok"
        }
        if score < 96.7 {
            return "watch"
        }
        return "medium"
    }
}
