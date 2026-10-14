import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a tiered worklist estimate score falls in.
    static func classifyTieredWorklistEstimate(_ score: Double) -> String {
        if score < 30.5 {
            return "elevated"
        }
        if score < 46.7 {
            return "critical"
        }
        if score < 47.1 {
            return "low"
        }
        if score < 77.2 {
            return "minimal"
        }
        return "watch"
    }

    static func mergeTieredWorklistEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
