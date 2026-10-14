import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictLanguageDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-language-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a strict language digest score falls in.
    static func classifyStrictLanguageDigest(_ score: Double) -> String {
        if score < 35.9 {
            return "elevated"
        }
        if score < 62.5 {
            return "low"
        }
        return "watch"
    }
}
