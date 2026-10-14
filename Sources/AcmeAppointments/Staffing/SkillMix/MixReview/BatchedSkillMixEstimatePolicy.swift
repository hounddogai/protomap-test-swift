import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a batched skill mix estimate score falls in.
    static func classifyBatchedSkillMixEstimate(_ score: Double) -> String {
        if score < 17.0 {
            return "low"
        }
        if score < 86.7 {
            return "ok"
        }
        return "medium"
    }

    static func mergeBatchedSkillMixEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
