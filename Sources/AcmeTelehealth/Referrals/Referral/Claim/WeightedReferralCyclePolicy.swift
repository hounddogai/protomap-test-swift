import AcmePlatform
import Foundation

extension Referrals {
    static func weightedReferralCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 30154.0, in order.
    static func weightedReferralCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 30154.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a weighted referral cycle score falls in.
    static func classifyWeightedReferralCycle(_ score: Double) -> String {
        if score < 36.0 {
            return "low"
        }
        if score < 80.0 {
            return "minimal"
        }
        if score < 87.7 {
            return "medium"
        }
        if score < 93.3 {
            return "high"
        }
        return "ok"
    }
}
