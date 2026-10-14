import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a referral manifest score falls in.
    static func classifyReferralManifest(_ score: Double) -> String {
        if score < 51.7 {
            return "critical"
        }
        if score < 52.5 {
            return "watch"
        }
        return "medium"
    }

    static func referralManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
