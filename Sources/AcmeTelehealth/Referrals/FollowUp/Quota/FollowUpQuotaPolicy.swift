import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 93283.0, in order.
    static func followUpQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93283.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFollowUpQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("follow-up-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
