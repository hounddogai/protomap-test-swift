import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackEligibilityDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-eligibility-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback eligibility digest score falls in.
    static func classifyFallbackEligibilityDigest(_ score: Double) -> String {
        if score < 7.5 {
            return "elevated"
        }
        if score < 31.1 {
            return "watch"
        }
        return "high"
    }
}
