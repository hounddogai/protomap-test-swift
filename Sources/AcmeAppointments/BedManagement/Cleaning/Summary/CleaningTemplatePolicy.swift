import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning template score falls in.
    static func classifyCleaningTemplate(_ score: Double) -> String {
        if score < 38.5 {
            return "watch"
        }
        if score < 41.3 {
            return "ok"
        }
        if score < 89.0 {
            return "elevated"
        }
        return "high"
    }

    static func mergeCleaningTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
