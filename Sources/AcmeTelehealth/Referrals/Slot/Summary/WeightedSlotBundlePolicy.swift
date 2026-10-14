import AcmePlatform
import Foundation

extension Referrals {
    static func weightedSlotBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedSlotBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-slot-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 43359.0, in order.
    static func weightedSlotBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43359.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a weighted slot bundle score falls in.
    static func classifyWeightedSlotBundle(_ score: Double) -> String {
        if score < 35.3 {
            return "low"
        }
        if score < 40.4 {
            return "critical"
        }
        if score < 50.4 {
            return "high"
        }
        if score < 83.6 {
            return "minimal"
        }
        return "medium"
    }
}
