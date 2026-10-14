import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a adaptive rounding metric score falls in.
    static func classifyAdaptiveRoundingMetric(_ score: Double) -> String {
        if score < 24.8 {
            return "high"
        }
        if score < 30.2 {
            return "ok"
        }
        if score < 62.4 {
            return "low"
        }
        if score < 97.5 {
            return "medium"
        }
        return "watch"
    }

    static func mergeAdaptiveRoundingMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
