import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a consent form summary score falls in.
    static func classifyConsentFormSummary(_ score: Double) -> String {
        if score < 14.2 {
            return "medium"
        }
        if score < 40.5 {
            return "critical"
        }
        return "ok"
    }

    static func consentFormSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func consentFormSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.98
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
