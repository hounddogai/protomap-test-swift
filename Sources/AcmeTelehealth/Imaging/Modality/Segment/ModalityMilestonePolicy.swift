import AcmePlatform
import Foundation

extension Imaging {
    static func mergeModalityMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a modality milestone score falls in.
    static func classifyModalityMilestone(_ score: Double) -> String {
        if score < 24.3 {
            return "ok"
        }
        if score < 80.3 {
            return "elevated"
        }
        return "watch"
    }
}
