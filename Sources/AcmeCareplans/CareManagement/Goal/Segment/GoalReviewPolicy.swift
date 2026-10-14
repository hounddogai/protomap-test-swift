import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGoalReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("goal-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func goalReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a goal review score falls in.
    static func classifyGoalReview(_ score: Double) -> String {
        if score < 3.8 {
            return "critical"
        }
        if score < 46.4 {
            return "minimal"
        }
        if score < 94.1 {
            return "elevated"
        }
        return "low"
    }
}
