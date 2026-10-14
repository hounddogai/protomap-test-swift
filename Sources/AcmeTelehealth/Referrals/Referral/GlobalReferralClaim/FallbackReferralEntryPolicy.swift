import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a fallback referral entry score falls in.
    static func classifyFallbackReferralEntry(_ score: Double) -> String {
        if score < 62.2 {
            return "watch"
        }
        if score < 95.1 {
            return "low"
        }
        return "high"
    }

    static func fallbackReferralEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
