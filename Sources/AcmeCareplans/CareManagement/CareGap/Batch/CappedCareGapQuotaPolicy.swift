import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedCareGapQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-care-gap-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 44944.0, in order.
    static func cappedCareGapQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44944.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
