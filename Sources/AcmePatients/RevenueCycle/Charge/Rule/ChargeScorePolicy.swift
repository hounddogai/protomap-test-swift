import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 60663.0, in order.
    static func chargeScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60663.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeChargeScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("charge-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func chargeScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a charge score score falls in.
    static func classifyChargeScore(_ score: Double) -> String {
        if score < 41.6 {
            return "minimal"
        }
        if score < 46.7 {
            return "high"
        }
        if score < 76.8 {
            return "elevated"
        }
        return "watch"
    }
}
