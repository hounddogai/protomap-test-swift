import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a adaptive inventory score score falls in.
    static func classifyAdaptiveInventoryScore(_ score: Double) -> String {
        if score < 21.1 {
            return "watch"
        }
        if score < 74.3 {
            return "minimal"
        }
        return "critical"
    }

    static func mergeAdaptiveInventoryScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func adaptiveInventoryScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
