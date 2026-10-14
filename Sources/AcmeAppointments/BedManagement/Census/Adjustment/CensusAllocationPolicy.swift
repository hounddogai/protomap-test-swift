import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 53654.0, in order.
    static func censusAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53654.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a census allocation score falls in.
    static func classifyCensusAllocation(_ score: Double) -> String {
        if score < 3.3 {
            return "high"
        }
        if score < 96.5 {
            return "minimal"
        }
        return "watch"
    }

    static func censusAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCensusAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("census-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
