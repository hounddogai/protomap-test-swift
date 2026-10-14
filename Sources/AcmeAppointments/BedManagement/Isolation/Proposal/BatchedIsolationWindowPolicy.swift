import AcmePlatform
import Foundation

extension BedManagement {
    static func batchedIsolationWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a batched isolation window score falls in.
    static func classifyBatchedIsolationWindow(_ score: Double) -> String {
        if score < 2.5 {
            return "critical"
        }
        if score < 4.7 {
            return "minimal"
        }
        if score < 32.6 {
            return "low"
        }
        if score < 43.5 {
            return "high"
        }
        return "watch"
    }

    static func mergeBatchedIsolationWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
