import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeGoalForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a goal forecast score falls in.
    static func classifyGoalForecast(_ score: Double) -> String {
        if score < 4.9 {
            return "critical"
        }
        if score < 65.3 {
            return "elevated"
        }
        if score < 72.6 {
            return "minimal"
        }
        if score < 74.8 {
            return "high"
        }
        return "medium"
    }
}
