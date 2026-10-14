import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a claim window score falls in.
    static func classifyClaimWindow(_ score: Double) -> String {
        if score < 5.1 {
            return "elevated"
        }
        if score < 34.1 {
            return "medium"
        }
        if score < 57.2 {
            return "high"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClaimWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("claim-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func claimWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
