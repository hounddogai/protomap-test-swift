import AcmePlatform
import Foundation

extension Imaging {
    static func mergeWorklistScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a worklist score score falls in.
    static func classifyWorklistScore(_ score: Double) -> String {
        if score < 16.1 {
            return "watch"
        }
        if score < 35.4 {
            return "minimal"
        }
        if score < 81.1 {
            return "elevated"
        }
        return "critical"
    }
}
