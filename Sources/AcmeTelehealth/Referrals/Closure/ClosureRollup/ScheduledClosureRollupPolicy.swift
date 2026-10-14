import AcmePlatform
import Foundation

extension Referrals {
    static func scheduledClosureRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.5
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledClosureRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-closure-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func scheduledClosureRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a scheduled closure rollup score falls in.
    static func classifyScheduledClosureRollup(_ score: Double) -> String {
        if score < 5.2 {
            return "elevated"
        }
        if score < 12.9 {
            return "high"
        }
        if score < 64.3 {
            return "low"
        }
        if score < 90.8 {
            return "critical"
        }
        return "medium"
    }
}
