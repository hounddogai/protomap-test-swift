import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDischargePlanRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("discharge-plan-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 81138.0, in order.
    static func dischargePlanRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 81138.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
