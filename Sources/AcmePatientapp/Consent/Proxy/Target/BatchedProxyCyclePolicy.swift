import AcmePlatform
import Foundation

extension Consent {
    static func batchedProxyCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedProxyCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-proxy-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 4639.0, in order.
    static func batchedProxyCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4639.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
