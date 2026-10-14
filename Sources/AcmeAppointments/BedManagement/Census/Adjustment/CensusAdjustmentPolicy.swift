import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 44817.0, in order.
    static func censusAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44817.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func censusAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCensusAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("census-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
