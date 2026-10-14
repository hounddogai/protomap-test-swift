import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a follow up rollup score falls in.
    static func classifyFollowUpRollup(_ score: Double) -> String {
        if score < 15.2 {
            return "minimal"
        }
        if score < 62.5 {
            return "high"
        }
        return "medium"
    }

    static func followUpRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func followUpRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
