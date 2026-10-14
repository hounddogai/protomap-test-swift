import AcmePlatform
import Foundation

extension Pharmacy {
    static func seasonalFormularyReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func seasonalFormularyReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a seasonal formulary review score falls in.
    static func classifySeasonalFormularyReview(_ score: Double) -> String {
        if score < 12.6 {
            return "watch"
        }
        if score < 55.2 {
            return "medium"
        }
        if score < 73.0 {
            return "high"
        }
        return "critical"
    }
}
