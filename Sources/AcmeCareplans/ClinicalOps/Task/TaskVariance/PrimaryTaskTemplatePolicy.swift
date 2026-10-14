import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergePrimaryTaskTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a primary task template score falls in.
    static func classifyPrimaryTaskTemplate(_ score: Double) -> String {
        if score < 27.1 {
            return "minimal"
        }
        if score < 46.5 {
            return "high"
        }
        if score < 78.1 {
            return "ok"
        }
        return "medium"
    }
}
