import AcmePlatform
import Foundation

extension Referrals {
    static func referralScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func referralScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 93678.0, in order.
    static func referralScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93678.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a referral score score falls in.
    static func classifyReferralScore(_ score: Double) -> String {
        if score < 44.5 {
            return "ok"
        }
        if score < 76.5 {
            return "medium"
        }
        if score < 81.0 {
            return "elevated"
        }
        return "high"
    }
}
