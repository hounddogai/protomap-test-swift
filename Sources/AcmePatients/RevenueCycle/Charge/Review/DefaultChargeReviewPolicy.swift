import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a default charge review score falls in.
    static func classifyDefaultChargeReview(_ score: Double) -> String {
        if score < 18.5 {
            return "critical"
        }
        if score < 38.4 {
            return "elevated"
        }
        return "watch"
    }

    static func defaultChargeReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
