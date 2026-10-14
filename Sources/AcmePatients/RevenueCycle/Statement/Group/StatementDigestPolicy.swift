import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a statement digest score falls in.
    static func classifyStatementDigest(_ score: Double) -> String {
        if score < 2.8 {
            return "elevated"
        }
        if score < 39.5 {
            return "medium"
        }
        if score < 60.1 {
            return "critical"
        }
        if score < 67.2 {
            return "high"
        }
        return "watch"
    }

    static func statementDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStatementDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("statement-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
