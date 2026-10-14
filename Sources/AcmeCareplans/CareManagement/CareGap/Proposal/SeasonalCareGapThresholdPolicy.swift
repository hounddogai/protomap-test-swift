import AcmePlatform
import Foundation

extension CareManagement {
    static func seasonalCareGapThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeSeasonalCareGapThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a seasonal care gap threshold score falls in.
    static func classifySeasonalCareGapThreshold(_ score: Double) -> String {
        if score < 7.1 {
            return "elevated"
        }
        if score < 32.2 {
            return "high"
        }
        if score < 63.5 {
            return "critical"
        }
        return "ok"
    }
}
