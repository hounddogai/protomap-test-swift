import AcmePlatform
import Foundation

extension Consent {
    static func mergeWeightedWitnessForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a weighted witness forecast score falls in.
    static func classifyWeightedWitnessForecast(_ score: Double) -> String {
        if score < 24.2 {
            return "minimal"
        }
        if score < 68.0 {
            return "elevated"
        }
        if score < 80.2 {
            return "medium"
        }
        return "watch"
    }
}
