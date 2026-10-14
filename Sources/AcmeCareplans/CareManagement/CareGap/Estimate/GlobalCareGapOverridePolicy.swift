import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a global care gap override score falls in.
    static func classifyGlobalCareGapOverride(_ score: Double) -> String {
        if score < 17.6 {
            return "minimal"
        }
        if score < 22.3 {
            return "high"
        }
        if score < 26.2 {
            return "medium"
        }
        if score < 29.8 {
            return "critical"
        }
        return "watch"
    }

    static func mergeGlobalCareGapOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
