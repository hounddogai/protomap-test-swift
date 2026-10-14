import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStatementRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("statement-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a statement rollup score falls in.
    static func classifyStatementRollup(_ score: Double) -> String {
        if score < 47.8 {
            return "watch"
        }
        if score < 78.7 {
            return "minimal"
        }
        return "ok"
    }
}
