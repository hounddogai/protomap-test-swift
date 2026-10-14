import AcmePlatform
import Foundation

extension Imaging {
    static func regionalStudyRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalStudyRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-study-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a regional study rule score falls in.
    static func classifyRegionalStudyRule(_ score: Double) -> String {
        if score < 1.0 {
            return "ok"
        }
        if score < 34.9 {
            return "watch"
        }
        if score < 88.4 {
            return "critical"
        }
        if score < 98.0 {
            return "high"
        }
        return "elevated"
    }
}
