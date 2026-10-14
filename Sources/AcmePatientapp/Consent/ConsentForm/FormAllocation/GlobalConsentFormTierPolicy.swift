import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a global consent form tier score falls in.
    static func classifyGlobalConsentFormTier(_ score: Double) -> String {
        if score < 3.0 {
            return "elevated"
        }
        if score < 51.5 {
            return "watch"
        }
        return "low"
    }

    static func globalConsentFormTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func globalConsentFormTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
