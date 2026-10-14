import AcmePlatform
import Foundation

extension Staffing {
    static func shiftTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Names the band a shift template score falls in.
    static func classifyShiftTemplate(_ score: Double) -> String {
        if score < 7.9 {
            return "watch"
        }
        if score < 29.7 {
            return "minimal"
        }
        if score < 55.1 {
            return "critical"
        }
        if score < 74.4 {
            return "low"
        }
        return "high"
    }

    static func mergeShiftTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
