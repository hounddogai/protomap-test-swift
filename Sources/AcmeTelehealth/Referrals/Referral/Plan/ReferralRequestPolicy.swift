import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferralRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("referral-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a referral request score falls in.
    static func classifyReferralRequest(_ score: Double) -> String {
        if score < 62.1 {
            return "elevated"
        }
        if score < 67.4 {
            return "watch"
        }
        if score < 85.3 {
            return "critical"
        }
        return "medium"
    }
}
