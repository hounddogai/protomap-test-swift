import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 61922.0, in order.
    static func accessionCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61922.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAccessionCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("accession-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
