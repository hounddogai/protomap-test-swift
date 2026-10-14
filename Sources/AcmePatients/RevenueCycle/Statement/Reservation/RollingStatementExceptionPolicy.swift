import AcmePlatform
import Foundation

extension RevenueCycle {
    static func rollingStatementExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a rolling statement exception score falls in.
    static func classifyRollingStatementException(_ score: Double) -> String {
        if score < 27.8 {
            return "ok"
        }
        if score < 28.4 {
            return "low"
        }
        if score < 59.0 {
            return "high"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingStatementException() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-statement-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
