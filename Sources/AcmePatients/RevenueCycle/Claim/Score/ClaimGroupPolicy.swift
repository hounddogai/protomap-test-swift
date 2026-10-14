import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClaimGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("claim-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func claimGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func claimGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a claim group score falls in.
    static func classifyClaimGroup(_ score: Double) -> String {
        if score < 41.1 {
            return "critical"
        }
        if score < 58.5 {
            return "watch"
        }
        if score < 74.7 {
            return "elevated"
        }
        return "high"
    }
}
