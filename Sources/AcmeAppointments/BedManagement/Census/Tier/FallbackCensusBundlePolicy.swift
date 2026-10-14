import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a fallback census bundle score falls in.
    static func classifyFallbackCensusBundle(_ score: Double) -> String {
        if score < 1.6 {
            return "medium"
        }
        if score < 36.5 {
            return "watch"
        }
        if score < 72.9 {
            return "ok"
        }
        return "elevated"
    }

    static func fallbackCensusBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    static func fallbackCensusBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeFallbackCensusBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
