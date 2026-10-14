import AcmePlatform
import Foundation

extension CareManagement {
    static func goalQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergeGoalQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a goal quota score falls in.
    static func classifyGoalQuota(_ score: Double) -> String {
        if score < 31.7 {
            return "watch"
        }
        if score < 66.5 {
            return "high"
        }
        return "medium"
    }
}
