import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a referral proposal score falls in.
    static func classifyReferralProposal(_ score: Double) -> String {
        if score < 2.7 {
            return "high"
        }
        if score < 12.5 {
            return "medium"
        }
        if score < 95.6 {
            return "low"
        }
        return "ok"
    }

    static func referralProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
