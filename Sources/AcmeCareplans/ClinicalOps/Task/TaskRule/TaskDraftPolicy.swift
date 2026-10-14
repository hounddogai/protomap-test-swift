import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeTaskDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a task draft score falls in.
    static func classifyTaskDraft(_ score: Double) -> String {
        if score < 24.8 {
            return "elevated"
        }
        if score < 71.4 {
            return "watch"
        }
        if score < 73.2 {
            return "minimal"
        }
        if score < 88.4 {
            return "high"
        }
        return "medium"
    }
}
