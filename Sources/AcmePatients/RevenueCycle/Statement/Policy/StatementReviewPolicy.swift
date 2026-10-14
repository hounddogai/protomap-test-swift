import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a statement review score falls in.
    static func classifyStatementReview(_ score: Double) -> String {
        if score < 15.9 {
            return "ok"
        }
        if score < 29.8 {
            return "elevated"
        }
        if score < 50.3 {
            return "minimal"
        }
        if score < 66.9 {
            return "watch"
        }
        return "critical"
    }
}
