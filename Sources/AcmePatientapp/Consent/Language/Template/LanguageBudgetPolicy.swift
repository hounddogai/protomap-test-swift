import AcmePlatform
import Foundation

extension Consent {
    static func languageBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a language budget score falls in.
    static func classifyLanguageBudget(_ score: Double) -> String {
        if score < 53.0 {
            return "minimal"
        }
        if score < 66.4 {
            return "critical"
        }
        if score < 76.7 {
            return "high"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLanguageBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("language-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
