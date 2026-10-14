import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a fallback float pool schedule score falls in.
    static func classifyFallbackFloatPoolSchedule(_ score: Double) -> String {
        if score < 8.8 {
            return "critical"
        }
        if score < 58.6 {
            return "watch"
        }
        if score < 75.1 {
            return "medium"
        }
        if score < 88.4 {
            return "ok"
        }
        return "minimal"
    }

    static func mergeFallbackFloatPoolScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
