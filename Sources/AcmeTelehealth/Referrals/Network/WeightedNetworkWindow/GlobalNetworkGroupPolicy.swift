import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a global network group score falls in.
    static func classifyGlobalNetworkGroup(_ score: Double) -> String {
        if score < 52.5 {
            return "ok"
        }
        if score < 56.5 {
            return "low"
        }
        if score < 63.2 {
            return "elevated"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalNetworkGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-network-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
