import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a adaptive panel estimate score falls in.
    static func classifyAdaptivePanelEstimate(_ score: Double) -> String {
        if score < 4.7 {
            return "minimal"
        }
        if score < 62.8 {
            return "low"
        }
        if score < 62.9 {
            return "watch"
        }
        if score < 86.5 {
            return "ok"
        }
        return "elevated"
    }

    static func adaptivePanelEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeAdaptivePanelEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
