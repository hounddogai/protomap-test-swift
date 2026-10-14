import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a rolling recall baseline score falls in.
    static func classifyRollingRecallBaseline(_ score: Double) -> String {
        if score < 27.8 {
            return "low"
        }
        if score < 43.3 {
            return "elevated"
        }
        if score < 66.7 {
            return "high"
        }
        if score < 85.9 {
            return "medium"
        }
        return "critical"
    }

    static func mergeRollingRecallBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
