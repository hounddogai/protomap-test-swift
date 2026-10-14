import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeFallbackCensusMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a fallback census metric score falls in.
    static func classifyFallbackCensusMetric(_ score: Double) -> String {
        if score < 7.4 {
            return "minimal"
        }
        if score < 46.8 {
            return "medium"
        }
        if score < 59.4 {
            return "elevated"
        }
        return "ok"
    }

    static func fallbackCensusMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
