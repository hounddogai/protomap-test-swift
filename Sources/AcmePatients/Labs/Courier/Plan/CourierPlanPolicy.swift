import AcmePlatform
import Foundation

extension Labs {
    static func courierPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a courier plan score falls in.
    static func classifyCourierPlan(_ score: Double) -> String {
        if score < 5.5 {
            return "critical"
        }
        if score < 42.0 {
            return "high"
        }
        if score < 71.9 {
            return "watch"
        }
        if score < 91.7 {
            return "medium"
        }
        return "elevated"
    }

    static func mergeCourierPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
