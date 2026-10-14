import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 73202.0, in order.
    static func batchedWitnessBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73202.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedWitnessBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedWitnessBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-witness-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
