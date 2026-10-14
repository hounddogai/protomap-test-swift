import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a consent form entry score falls in.
    static func classifyConsentFormEntry(_ score: Double) -> String {
        if score < 35.7 {
            return "medium"
        }
        if score < 50.5 {
            return "high"
        }
        if score < 57.7 {
            return "watch"
        }
        return "minimal"
    }

    static func consentFormEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
