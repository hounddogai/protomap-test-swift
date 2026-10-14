import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilityBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a eligibility bundle score falls in.
    static func classifyEligibilityBundle(_ score: Double) -> String {
        if score < 5.5 {
            return "watch"
        }
        if score < 35.0 {
            return "medium"
        }
        if score < 54.0 {
            return "low"
        }
        if score < 94.6 {
            return "minimal"
        }
        return "high"
    }
}
