import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedAccessionEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-accession-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 76673.0, in order.
    static func batchedAccessionEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76673.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
