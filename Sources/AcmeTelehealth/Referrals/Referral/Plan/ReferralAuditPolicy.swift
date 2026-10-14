import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 6716.0, in order.
    static func referralAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 6716.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferralAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("referral-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
