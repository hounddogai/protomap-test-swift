import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 3045.0, in order.
    static func weightedWorklistBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3045.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func weightedWorklistBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedWorklistBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-worklist-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
