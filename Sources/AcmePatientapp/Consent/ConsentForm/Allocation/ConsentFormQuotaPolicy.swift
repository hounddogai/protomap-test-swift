import AcmePlatform
import Foundation

extension Consent {
    static func consentFormQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a consent form quota score falls in.
    static func classifyConsentFormQuota(_ score: Double) -> String {
        if score < 8.5 {
            return "low"
        }
        if score < 41.7 {
            return "minimal"
        }
        if score < 43.0 {
            return "ok"
        }
        if score < 46.7 {
            return "watch"
        }
        return "critical"
    }
}
