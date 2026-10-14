import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultReferralMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-referral-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func defaultReferralMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func defaultReferralMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
