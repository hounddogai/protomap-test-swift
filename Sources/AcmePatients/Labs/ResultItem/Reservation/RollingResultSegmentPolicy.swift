import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingResultSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-result-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rolling result segment score falls in.
    static func classifyRollingResultSegment(_ score: Double) -> String {
        if score < 26.3 {
            return "watch"
        }
        if score < 41.0 {
            return "minimal"
        }
        if score < 82.1 {
            return "low"
        }
        if score < 90.7 {
            return "ok"
        }
        return "high"
    }

    static func rollingResultSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
