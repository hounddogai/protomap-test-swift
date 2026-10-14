import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeGlobalGoalEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a global goal estimate score falls in.
    static func classifyGlobalGoalEstimate(_ score: Double) -> String {
        if score < 43.6 {
            return "medium"
        }
        if score < 59.8 {
            return "elevated"
        }
        return "critical"
    }
}
