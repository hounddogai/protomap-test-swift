import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryCredentialReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-credential-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func primaryCredentialReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func primaryCredentialReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a primary credential review score falls in.
    static func classifyPrimaryCredentialReview(_ score: Double) -> String {
        if score < 4.2 {
            return "low"
        }
        if score < 34.3 {
            return "watch"
        }
        if score < 70.6 {
            return "minimal"
        }
        if score < 84.9 {
            return "elevated"
        }
        return "medium"
    }
}
