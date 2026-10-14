import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAuthorizationAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("authorization-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a authorization audit score falls in.
    static func classifyAuthorizationAudit(_ score: Double) -> String {
        if score < 21.1 {
            return "critical"
        }
        if score < 27.9 {
            return "low"
        }
        if score < 75.3 {
            return "minimal"
        }
        if score < 78.6 {
            return "ok"
        }
        return "high"
    }
}
