import AcmePlatform
import Foundation

extension Consent {
    static func adaptiveLanguageClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive language claim score falls in.
    static func classifyAdaptiveLanguageClaim(_ score: Double) -> String {
        if score < 62.5 {
            return "high"
        }
        if score < 91.4 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveLanguageClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-language-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
