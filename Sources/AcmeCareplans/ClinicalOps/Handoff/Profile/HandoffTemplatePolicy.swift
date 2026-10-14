import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a handoff template score falls in.
    static func classifyHandoffTemplate(_ score: Double) -> String {
        if score < 39.1 {
            return "elevated"
        }
        if score < 96.9 {
            return "high"
        }
        return "ok"
    }

    static func mergeHandoffTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
