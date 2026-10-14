import AcmePlatform
import Foundation

extension Consent {
    static func mergeSeasonalLanguageRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func seasonalLanguageRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Names the band a seasonal language request score falls in.
    static func classifySeasonalLanguageRequest(_ score: Double) -> String {
        if score < 7.8 {
            return "minimal"
        }
        if score < 42.7 {
            return "ok"
        }
        if score < 47.8 {
            return "watch"
        }
        if score < 96.5 {
            return "elevated"
        }
        return "high"
    }
}
