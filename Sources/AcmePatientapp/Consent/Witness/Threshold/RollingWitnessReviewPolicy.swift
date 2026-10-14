import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 70624.0, in order.
    static func rollingWitnessReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70624.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingWitnessReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-witness-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rolling witness review score falls in.
    static func classifyRollingWitnessReview(_ score: Double) -> String {
        if score < 5.9 {
            return "high"
        }
        if score < 7.7 {
            return "critical"
        }
        if score < 11.9 {
            return "elevated"
        }
        if score < 98.2 {
            return "ok"
        }
        return "watch"
    }

    static func rollingWitnessReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
