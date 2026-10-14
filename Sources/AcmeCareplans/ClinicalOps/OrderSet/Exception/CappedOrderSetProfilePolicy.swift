import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedOrderSetProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-order-set-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 77546.0, in order.
    static func cappedOrderSetProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77546.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
