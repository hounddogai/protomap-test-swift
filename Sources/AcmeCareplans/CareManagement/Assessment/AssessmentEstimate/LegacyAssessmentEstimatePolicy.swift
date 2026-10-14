import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeLegacyAssessmentEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a legacy assessment estimate score falls in.
    static func classifyLegacyAssessmentEstimate(_ score: Double) -> String {
        if score < 28.4 {
            return "ok"
        }
        if score < 46.0 {
            return "elevated"
        }
        if score < 94.3 {
            return "watch"
        }
        return "high"
    }

    static func legacyAssessmentEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
