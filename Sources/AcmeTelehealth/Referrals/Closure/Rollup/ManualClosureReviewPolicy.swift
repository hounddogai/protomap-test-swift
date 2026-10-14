import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a manual closure review score falls in.
    static func classifyManualClosureReview(_ score: Double) -> String {
        if score < 14.1 {
            return "medium"
        }
        if score < 30.5 {
            return "low"
        }
        if score < 59.7 {
            return "watch"
        }
        return "critical"
    }

    static func manualClosureReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
