import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeIsolationTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func isolationTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a isolation target score falls in.
    static func classifyIsolationTarget(_ score: Double) -> String {
        if score < 49.3 {
            return "ok"
        }
        if score < 51.8 {
            return "watch"
        }
        if score < 69.9 {
            return "low"
        }
        return "minimal"
    }
}
