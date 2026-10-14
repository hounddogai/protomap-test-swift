import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledNetworkRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-network-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a scheduled network rule score falls in.
    static func classifyScheduledNetworkRule(_ score: Double) -> String {
        if score < 42.1 {
            return "minimal"
        }
        if score < 75.7 {
            return "watch"
        }
        return "low"
    }
}
