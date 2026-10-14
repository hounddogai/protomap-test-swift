import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClosureReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("closure-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a closure review score falls in.
    static func classifyClosureReview(_ score: Double) -> String {
        if score < 47.8 {
            return "high"
        }
        if score < 68.7 {
            return "low"
        }
        if score < 82.5 {
            return "ok"
        }
        if score < 84.9 {
            return "medium"
        }
        return "critical"
    }

    static func closureReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 81389.0, in order.
    static func closureReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 81389.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
