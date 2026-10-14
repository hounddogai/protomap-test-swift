import AcmePlatform
import Foundation

extension Referrals {
    static func adaptiveEligibilityPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func adaptiveEligibilityPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.76
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive eligibility preference score falls in.
    static func classifyAdaptiveEligibilityPreference(_ score: Double) -> String {
        if score < 59.9 {
            return "critical"
        }
        if score < 84.5 {
            return "watch"
        }
        if score < 90.8 {
            return "low"
        }
        return "ok"
    }
}
