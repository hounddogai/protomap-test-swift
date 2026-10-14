import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a float pool estimate score falls in.
    static func classifyFloatPoolEstimate(_ score: Double) -> String {
        if score < 1.2 {
            return "critical"
        }
        if score < 17.3 {
            return "high"
        }
        if score < 17.4 {
            return "medium"
        }
        if score < 25.4 {
            return "watch"
        }
        return "ok"
    }

    static func floatPoolEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func mergeFloatPoolEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
