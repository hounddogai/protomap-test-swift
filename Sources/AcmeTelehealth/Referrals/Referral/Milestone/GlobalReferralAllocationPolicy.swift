import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 60218.0, in order.
    static func globalReferralAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60218.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a global referral allocation score falls in.
    static func classifyGlobalReferralAllocation(_ score: Double) -> String {
        if score < 46.4 {
            return "elevated"
        }
        if score < 77.3 {
            return "high"
        }
        return "ok"
    }
}
