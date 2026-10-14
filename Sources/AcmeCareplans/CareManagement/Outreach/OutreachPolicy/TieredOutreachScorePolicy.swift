import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a tiered outreach score score falls in.
    static func classifyTieredOutreachScore(_ score: Double) -> String {
        if score < 12.8 {
            return "ok"
        }
        if score < 17.8 {
            return "elevated"
        }
        if score < 34.9 {
            return "watch"
        }
        if score < 64.2 {
            return "critical"
        }
        return "high"
    }

    static func tieredOutreachScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.4
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
