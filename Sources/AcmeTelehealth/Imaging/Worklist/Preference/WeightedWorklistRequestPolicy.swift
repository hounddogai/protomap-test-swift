import AcmePlatform
import Foundation

extension Imaging {
    static func weightedWorklistRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a weighted worklist request score falls in.
    static func classifyWeightedWorklistRequest(_ score: Double) -> String {
        if score < 8.4 {
            return "ok"
        }
        if score < 61.0 {
            return "watch"
        }
        return "low"
    }

    static func weightedWorklistRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeWeightedWorklistRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
