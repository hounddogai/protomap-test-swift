import AcmePlatform
import Foundation

extension Consent {
    static func fallbackRevocationPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackRevocationPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-revocation-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback revocation preference score falls in.
    static func classifyFallbackRevocationPreference(_ score: Double) -> String {
        if score < 25.6 {
            return "high"
        }
        if score < 65.0 {
            return "watch"
        }
        if score < 66.0 {
            return "minimal"
        }
        return "low"
    }
}
