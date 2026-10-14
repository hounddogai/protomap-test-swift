import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 29797.0, in order.
    static func scheduledCourierReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29797.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledCourierReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func scheduledCourierReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledCourierReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-courier-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
