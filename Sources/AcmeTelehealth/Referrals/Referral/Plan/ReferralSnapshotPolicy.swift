import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferralSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("referral-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func referralSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a referral snapshot score falls in.
    static func classifyReferralSnapshot(_ score: Double) -> String {
        if score < 11.3 {
            return "critical"
        }
        if score < 22.2 {
            return "high"
        }
        if score < 49.1 {
            return "medium"
        }
        return "low"
    }
}
