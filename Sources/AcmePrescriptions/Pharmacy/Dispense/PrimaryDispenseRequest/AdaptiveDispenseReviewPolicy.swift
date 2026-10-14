import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveDispenseReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-dispense-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a adaptive dispense review score falls in.
    static func classifyAdaptiveDispenseReview(_ score: Double) -> String {
        if score < 7.8 {
            return "elevated"
        }
        if score < 94.5 {
            return "critical"
        }
        return "low"
    }

    static func adaptiveDispenseReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func adaptiveDispenseReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
