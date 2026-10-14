import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a referral summary score falls in.
    static func classifyReferralSummary(_ score: Double) -> String {
        if score < 2.8 {
            return "minimal"
        }
        if score < 11.5 {
            return "critical"
        }
        if score < 39.3 {
            return "watch"
        }
        if score < 87.8 {
            return "high"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 12721.0, in order.
    static func referralSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12721.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func referralSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
