import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 92933.0, in order.
    static func pendingReferenceRangeBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92933.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingReferenceRangeBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-reference-range-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func pendingReferenceRangeBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
