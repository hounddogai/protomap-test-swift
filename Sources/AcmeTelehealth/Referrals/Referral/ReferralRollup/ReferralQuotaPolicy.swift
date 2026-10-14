import AcmePlatform
import Foundation

extension Referrals {
    static func referralQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a referral quota score falls in.
    static func classifyReferralQuota(_ score: Double) -> String {
        if score < 15.1 {
            return "medium"
        }
        if score < 35.6 {
            return "critical"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferralQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("referral-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
