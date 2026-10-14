import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a revocation claim score falls in.
    static func classifyRevocationClaim(_ score: Double) -> String {
        if score < 45.8 {
            return "critical"
        }
        if score < 48.3 {
            return "high"
        }
        if score < 80.8 {
            return "ok"
        }
        return "low"
    }

    static func revocationClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
