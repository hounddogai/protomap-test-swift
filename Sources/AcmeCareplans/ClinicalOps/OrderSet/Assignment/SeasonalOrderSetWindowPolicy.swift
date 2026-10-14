import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeSeasonalOrderSetWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a seasonal order set window score falls in.
    static func classifySeasonalOrderSetWindow(_ score: Double) -> String {
        if score < 18.4 {
            return "watch"
        }
        if score < 42.0 {
            return "high"
        }
        if score < 74.1 {
            return "low"
        }
        return "minimal"
    }
}
