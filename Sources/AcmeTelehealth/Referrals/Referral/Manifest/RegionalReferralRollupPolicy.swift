import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a regional referral rollup score falls in.
    static func classifyRegionalReferralRollup(_ score: Double) -> String {
        if score < 55.0 {
            return "high"
        }
        if score < 59.8 {
            return "elevated"
        }
        if score < 87.5 {
            return "medium"
        }
        if score < 94.9 {
            return "low"
        }
        return "critical"
    }

    static func regionalReferralRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
