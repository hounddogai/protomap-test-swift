import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCredentialReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("credential-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a credential review score falls in.
    static func classifyCredentialReview(_ score: Double) -> String {
        if score < 36.9 {
            return "minimal"
        }
        if score < 54.6 {
            return "elevated"
        }
        if score < 67.8 {
            return "high"
        }
        if score < 74.3 {
            return "ok"
        }
        return "watch"
    }

    static func credentialReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func credentialReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
