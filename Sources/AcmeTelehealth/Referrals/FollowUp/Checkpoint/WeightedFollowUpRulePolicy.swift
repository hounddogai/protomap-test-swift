import AcmePlatform
import Foundation

extension Referrals {
    static func weightedFollowUpRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a weighted follow up rule score falls in.
    static func classifyWeightedFollowUpRule(_ score: Double) -> String {
        if score < 32.1 {
            return "watch"
        }
        if score < 52.0 {
            return "high"
        }
        if score < 75.5 {
            return "elevated"
        }
        return "low"
    }
}
