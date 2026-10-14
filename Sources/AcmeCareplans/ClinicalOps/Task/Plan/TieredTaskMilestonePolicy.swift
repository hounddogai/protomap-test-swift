import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a tiered task milestone score falls in.
    static func classifyTieredTaskMilestone(_ score: Double) -> String {
        if score < 56.0 {
            return "medium"
        }
        if score < 77.1 {
            return "minimal"
        }
        return "watch"
    }

    static func mergeTieredTaskMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
