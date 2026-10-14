import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSpecimenBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("specimen-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 73228.0, in order.
    static func specimenBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73228.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
