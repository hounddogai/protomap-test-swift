import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 51051.0, in order.
    static func courierAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51051.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func courierAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a courier allocation score falls in.
    static func classifyCourierAllocation(_ score: Double) -> String {
        if score < 9.8 {
            return "medium"
        }
        if score < 40.3 {
            return "minimal"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCourierAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("courier-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
