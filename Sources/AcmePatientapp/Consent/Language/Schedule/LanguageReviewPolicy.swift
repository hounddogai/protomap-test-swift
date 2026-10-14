import AcmePlatform
import Foundation

extension Consent {
    static func languageReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a language review score falls in.
    static func classifyLanguageReview(_ score: Double) -> String {
        if score < 28.0 {
            return "high"
        }
        if score < 56.4 {
            return "medium"
        }
        if score < 93.8 {
            return "watch"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLanguageReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("language-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func languageReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.05
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
