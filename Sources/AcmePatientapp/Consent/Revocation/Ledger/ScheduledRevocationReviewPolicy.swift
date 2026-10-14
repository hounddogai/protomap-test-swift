import AcmePlatform
import Foundation

extension Consent {
    static func scheduledRevocationReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func scheduledRevocationReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a scheduled revocation review score falls in.
    static func classifyScheduledRevocationReview(_ score: Double) -> String {
        if score < 15.0 {
            return "low"
        }
        if score < 76.6 {
            return "ok"
        }
        return "minimal"
    }

    static func scheduledRevocationReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
