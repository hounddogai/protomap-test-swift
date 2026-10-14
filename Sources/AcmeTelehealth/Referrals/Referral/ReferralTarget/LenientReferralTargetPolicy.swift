import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 19062.0, in order.
    static func lenientReferralTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19062.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a lenient referral target score falls in.
    static func classifyLenientReferralTarget(_ score: Double) -> String {
        if score < 16.5 {
            return "ok"
        }
        if score < 23.1 {
            return "high"
        }
        return "low"
    }

    static func lenientReferralTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientReferralTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-referral-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
