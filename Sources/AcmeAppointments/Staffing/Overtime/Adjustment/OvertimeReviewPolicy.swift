import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 31090.0, in order.
    static func overtimeReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31090.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
