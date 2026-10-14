import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeShiftCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("shift-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 39458.0, in order.
    static func shiftCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39458.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
