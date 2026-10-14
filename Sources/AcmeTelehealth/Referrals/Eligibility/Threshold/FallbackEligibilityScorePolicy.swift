import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a fallback eligibility score score falls in.
    static func classifyFallbackEligibilityScore(_ score: Double) -> String {
        if score < 6.1 {
            return "ok"
        }
        if score < 10.9 {
            return "watch"
        }
        if score < 74.0 {
            return "critical"
        }
        if score < 81.6 {
            return "minimal"
        }
        return "medium"
    }

    static func fallbackEligibilityScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
