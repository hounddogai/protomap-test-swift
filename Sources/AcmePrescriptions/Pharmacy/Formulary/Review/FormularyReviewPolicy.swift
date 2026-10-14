import AcmePlatform
import Foundation

extension Pharmacy {
    static func formularyReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func formularyReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a formulary review score falls in.
    static func classifyFormularyReview(_ score: Double) -> String {
        if score < 19.4 {
            return "ok"
        }
        if score < 31.0 {
            return "critical"
        }
        if score < 79.8 {
            return "high"
        }
        return "minimal"
    }
}
