import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilityRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a eligibility rule score falls in.
    static func classifyEligibilityRule(_ score: Double) -> String {
        if score < 8.8 {
            return "high"
        }
        if score < 24.9 {
            return "low"
        }
        if score < 78.2 {
            return "elevated"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 84969.0, in order.
    static func eligibilityRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84969.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
