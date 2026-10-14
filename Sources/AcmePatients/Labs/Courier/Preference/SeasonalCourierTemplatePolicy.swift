import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a seasonal courier template score falls in.
    static func classifySeasonalCourierTemplate(_ score: Double) -> String {
        if score < 33.8 {
            return "watch"
        }
        if score < 90.8 {
            return "elevated"
        }
        return "high"
    }

    static func seasonalCourierTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func seasonalCourierTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeSeasonalCourierTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
