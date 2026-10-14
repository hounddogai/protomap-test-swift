import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 88221.0, in order.
    static func pendingShiftReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 88221.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingShiftReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-shift-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
