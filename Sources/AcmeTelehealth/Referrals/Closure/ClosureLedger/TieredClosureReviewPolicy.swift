import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a tiered closure review score falls in.
    static func classifyTieredClosureReview(_ score: Double) -> String {
        if score < 13.0 {
            return "ok"
        }
        if score < 57.3 {
            return "elevated"
        }
        if score < 60.2 {
            return "watch"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 33654.0, in order.
    static func tieredClosureReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 33654.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func tieredClosureReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredClosureReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-closure-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
