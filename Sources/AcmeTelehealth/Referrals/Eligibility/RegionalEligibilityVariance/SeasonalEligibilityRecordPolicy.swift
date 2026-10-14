import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a seasonal eligibility record score falls in.
    static func classifySeasonalEligibilityRecord(_ score: Double) -> String {
        if score < 40.4 {
            return "elevated"
        }
        if score < 91.3 {
            return "critical"
        }
        return "high"
    }

    static func seasonalEligibilityRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
