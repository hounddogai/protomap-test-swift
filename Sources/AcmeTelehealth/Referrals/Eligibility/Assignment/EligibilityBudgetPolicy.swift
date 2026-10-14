import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilityBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a eligibility budget score falls in.
    static func classifyEligibilityBudget(_ score: Double) -> String {
        if score < 8.0 {
            return "critical"
        }
        if score < 65.3 {
            return "high"
        }
        return "watch"
    }

    static func eligibilityBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
