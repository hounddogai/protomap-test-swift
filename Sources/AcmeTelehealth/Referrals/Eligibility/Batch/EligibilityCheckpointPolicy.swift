import AcmePlatform
import Foundation

extension Referrals {
    static func eligibilityCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 29806.0, in order.
    static func eligibilityCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29806.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
