import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a weighted referral audit score falls in.
    static func classifyWeightedReferralAudit(_ score: Double) -> String {
        if score < 18.0 {
            return "medium"
        }
        if score < 27.5 {
            return "ok"
        }
        if score < 69.2 {
            return "critical"
        }
        if score < 95.8 {
            return "minimal"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 1910.0, in order.
    static func weightedReferralAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1910.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
