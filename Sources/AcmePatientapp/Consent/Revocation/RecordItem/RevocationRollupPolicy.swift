import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a revocation rollup score falls in.
    static func classifyRevocationRollup(_ score: Double) -> String {
        if score < 9.5 {
            return "minimal"
        }
        if score < 42.1 {
            return "critical"
        }
        if score < 44.7 {
            return "elevated"
        }
        if score < 47.7 {
            return "watch"
        }
        return "ok"
    }

    static func revocationRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
