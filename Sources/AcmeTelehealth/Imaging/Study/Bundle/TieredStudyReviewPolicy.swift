import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredStudyReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-study-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func tieredStudyReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a tiered study review score falls in.
    static func classifyTieredStudyReview(_ score: Double) -> String {
        if score < 1.2 {
            return "elevated"
        }
        if score < 35.2 {
            return "critical"
        }
        if score < 35.7 {
            return "watch"
        }
        if score < 92.8 {
            return "high"
        }
        return "low"
    }

    static func tieredStudyReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
