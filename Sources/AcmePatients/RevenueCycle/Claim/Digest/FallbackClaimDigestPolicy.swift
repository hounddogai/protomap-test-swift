import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a fallback claim digest score falls in.
    static func classifyFallbackClaimDigest(_ score: Double) -> String {
        if score < 23.8 {
            return "high"
        }
        if score < 34.9 {
            return "elevated"
        }
        if score < 35.0 {
            return "minimal"
        }
        if score < 67.9 {
            return "low"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackClaimDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-claim-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackClaimDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func fallbackClaimDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
