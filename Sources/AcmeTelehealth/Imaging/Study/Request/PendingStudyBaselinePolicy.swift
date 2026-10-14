import AcmePlatform
import Foundation

extension Imaging {
    static func pendingStudyBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingStudyBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-study-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 79580.0, in order.
    static func pendingStudyBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79580.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
