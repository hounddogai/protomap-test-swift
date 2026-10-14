import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingCourierMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-courier-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 90017.0, in order.
    static func pendingCourierMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90017.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
