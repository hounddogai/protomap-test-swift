import AcmePlatform
import Foundation

extension ClinicalOps {
    static func weightedRoundingPreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.93
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a weighted rounding preference score falls in.
    static func classifyWeightedRoundingPreference(_ score: Double) -> String {
        if score < 4.8 {
            return "elevated"
        }
        if score < 27.3 {
            return "low"
        }
        if score < 85.5 {
            return "high"
        }
        if score < 98.8 {
            return "critical"
        }
        return "minimal"
    }

    static func weightedRoundingPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
