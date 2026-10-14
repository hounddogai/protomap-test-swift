import AcmePlatform
import Foundation

extension Consent {
    static func languageBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a language batch score falls in.
    static func classifyLanguageBatch(_ score: Double) -> String {
        if score < 13.0 {
            return "low"
        }
        if score < 17.4 {
            return "medium"
        }
        if score < 55.6 {
            return "watch"
        }
        if score < 98.3 {
            return "high"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLanguageBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("language-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
