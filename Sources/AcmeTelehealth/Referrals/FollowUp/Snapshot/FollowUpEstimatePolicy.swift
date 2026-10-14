import AcmePlatform
import Foundation

extension Referrals {
    static func followUpEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func followUpEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a follow up estimate score falls in.
    static func classifyFollowUpEstimate(_ score: Double) -> String {
        if score < 26.0 {
            return "watch"
        }
        if score < 27.6 {
            return "critical"
        }
        if score < 41.2 {
            return "minimal"
        }
        return "medium"
    }
}
