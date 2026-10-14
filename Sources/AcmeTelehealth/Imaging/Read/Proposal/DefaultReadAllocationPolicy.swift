import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 97438.0, in order.
    static func defaultReadAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97438.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a default read allocation score falls in.
    static func classifyDefaultReadAllocation(_ score: Double) -> String {
        if score < 21.3 {
            return "minimal"
        }
        if score < 49.2 {
            return "high"
        }
        if score < 62.2 {
            return "watch"
        }
        if score < 69.0 {
            return "elevated"
        }
        return "medium"
    }

    static func defaultReadAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultReadAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-read-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
