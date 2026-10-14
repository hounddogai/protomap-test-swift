import AcmePlatform
import Foundation

extension Consent {
    static func batchedProxyOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedProxyOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-proxy-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 24905.0, in order.
    static func batchedProxyOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 24905.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
