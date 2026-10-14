import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a adaptive risk score threshold score falls in.
    static func classifyAdaptiveRiskScoreThreshold(_ score: Double) -> String {
        if score < 42.6 {
            return "watch"
        }
        if score < 75.6 {
            return "elevated"
        }
        if score < 94.6 {
            return "critical"
        }
        return "low"
    }

    static func adaptiveRiskScoreThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func mergeAdaptiveRiskScoreThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
