import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a goal score score falls in.
    static func classifyGoalScore(_ score: Double) -> String {
        if score < 14.8 {
            return "low"
        }
        if score < 29.5 {
            return "high"
        }
        if score < 70.8 {
            return "critical"
        }
        return "ok"
    }

    static func mergeGoalScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
