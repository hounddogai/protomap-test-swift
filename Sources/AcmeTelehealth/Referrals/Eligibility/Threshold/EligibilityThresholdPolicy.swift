import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilityThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a eligibility threshold score falls in.
    static func classifyEligibilityThreshold(_ score: Double) -> String {
        if score < 24.0 {
            return "watch"
        }
        if score < 25.9 {
            return "high"
        }
        if score < 36.6 {
            return "ok"
        }
        if score < 37.6 {
            return "medium"
        }
        return "minimal"
    }

    static func eligibilityThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 24228.0, in order.
    static func eligibilityThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24228.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
