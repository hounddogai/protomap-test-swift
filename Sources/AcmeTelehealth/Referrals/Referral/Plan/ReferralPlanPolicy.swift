import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a referral plan score falls in.
    static func classifyReferralPlan(_ score: Double) -> String {
        if score < 14.4 {
            return "critical"
        }
        if score < 65.8 {
            return "high"
        }
        return "low"
    }

    static func referralPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
