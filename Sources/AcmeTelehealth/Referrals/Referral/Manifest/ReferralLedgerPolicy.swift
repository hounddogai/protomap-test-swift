import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 76816.0, in order.
    static func referralLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76816.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a referral ledger score falls in.
    static func classifyReferralLedger(_ score: Double) -> String {
        if score < 13.4 {
            return "low"
        }
        if score < 27.2 {
            return "elevated"
        }
        if score < 46.8 {
            return "watch"
        }
        if score < 65.0 {
            return "medium"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferralLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("referral-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
