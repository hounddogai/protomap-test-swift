import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a courier window score falls in.
    static func classifyCourierWindow(_ score: Double) -> String {
        if score < 1.2 {
            return "low"
        }
        if score < 4.6 {
            return "high"
        }
        if score < 75.9 {
            return "elevated"
        }
        return "watch"
    }

    static func courierWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func mergeCourierWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
