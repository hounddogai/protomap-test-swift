import AcmePlatform
import Foundation

extension Pharmacy {
    static func rollingDispenseRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a rolling dispense rule score falls in.
    static func classifyRollingDispenseRule(_ score: Double) -> String {
        if score < 6.2 {
            return "watch"
        }
        if score < 37.7 {
            return "medium"
        }
        if score < 50.1 {
            return "minimal"
        }
        if score < 62.8 {
            return "ok"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingDispenseRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-dispense-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
