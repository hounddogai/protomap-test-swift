import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a referral cycle score falls in.
    static func classifyReferralCycle(_ score: Double) -> String {
        if score < 26.9 {
            return "minimal"
        }
        if score < 37.3 {
            return "low"
        }
        if score < 45.4 {
            return "medium"
        }
        if score < 60.7 {
            return "watch"
        }
        return "high"
    }

    static func referralCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
