import AcmePlatform
import Foundation

extension Referrals {
    static func cappedSlotProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func cappedSlotProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a capped slot profile score falls in.
    static func classifyCappedSlotProfile(_ score: Double) -> String {
        if score < 25.6 {
            return "critical"
        }
        if score < 82.6 {
            return "low"
        }
        return "medium"
    }
}
