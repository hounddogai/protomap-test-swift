import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a recall exception score falls in.
    static func classifyRecallException(_ score: Double) -> String {
        if score < 30.6 {
            return "high"
        }
        if score < 32.9 {
            return "medium"
        }
        if score < 77.6 {
            return "watch"
        }
        return "minimal"
    }

    static func recallExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    static func mergeRecallExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
