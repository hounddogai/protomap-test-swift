import AcmePlatform
import Foundation

extension Imaging {
    static func mergeSeasonalReadGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func seasonalReadGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a seasonal read group score falls in.
    static func classifySeasonalReadGroup(_ score: Double) -> String {
        if score < 18.3 {
            return "medium"
        }
        if score < 28.1 {
            return "minimal"
        }
        if score < 29.9 {
            return "high"
        }
        if score < 67.0 {
            return "low"
        }
        return "critical"
    }
}
