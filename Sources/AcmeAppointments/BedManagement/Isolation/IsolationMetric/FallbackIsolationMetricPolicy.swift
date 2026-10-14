import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeFallbackIsolationMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a fallback isolation metric score falls in.
    static func classifyFallbackIsolationMetric(_ score: Double) -> String {
        if score < 31.9 {
            return "watch"
        }
        if score < 49.4 {
            return "high"
        }
        if score < 89.4 {
            return "ok"
        }
        return "elevated"
    }
}
