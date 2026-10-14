import AcmePlatform
import Foundation

extension Referrals {
    static func referralThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 93147.0, in order.
    static func referralThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93147.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a referral threshold score falls in.
    static func classifyReferralThreshold(_ score: Double) -> String {
        if score < 3.6 {
            return "ok"
        }
        if score < 30.2 {
            return "watch"
        }
        if score < 51.1 {
            return "low"
        }
        return "elevated"
    }
}
