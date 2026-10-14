import AcmePlatform
import Foundation

extension RevenueCycle {
    static func batchedAuthorizationEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a batched authorization entry score falls in.
    static func classifyBatchedAuthorizationEntry(_ score: Double) -> String {
        if score < 47.9 {
            return "ok"
        }
        if score < 65.4 {
            return "minimal"
        }
        if score < 93.6 {
            return "critical"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedAuthorizationEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-authorization-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 20795.0, in order.
    static func batchedAuthorizationEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20795.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
