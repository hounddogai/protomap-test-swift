import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeClaimMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a claim metric score falls in.
    static func classifyClaimMetric(_ score: Double) -> String {
        if score < 11.4 {
            return "high"
        }
        if score < 16.1 {
            return "elevated"
        }
        if score < 25.9 {
            return "minimal"
        }
        if score < 54.0 {
            return "critical"
        }
        return "watch"
    }
}
