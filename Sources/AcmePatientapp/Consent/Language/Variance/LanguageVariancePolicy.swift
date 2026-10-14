import AcmePlatform
import Foundation

extension Consent {
    static func languageVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a language variance score falls in.
    static func classifyLanguageVariance(_ score: Double) -> String {
        if score < 29.2 {
            return "critical"
        }
        if score < 84.4 {
            return "low"
        }
        return "elevated"
    }
}
