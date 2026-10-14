import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a weighted referral proposal score falls in.
    static func classifyWeightedReferralProposal(_ score: Double) -> String {
        if score < 42.0 {
            return "elevated"
        }
        if score < 76.1 {
            return "watch"
        }
        return "high"
    }

    static func weightedReferralProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func weightedReferralProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 41763.0, in order.
    static func weightedReferralProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41763.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
