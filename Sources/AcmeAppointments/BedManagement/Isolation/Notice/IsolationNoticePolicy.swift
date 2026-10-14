import AcmePlatform
import Foundation

extension BedManagement {
    static func isolationNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a isolation notice score falls in.
    static func classifyIsolationNotice(_ score: Double) -> String {
        if score < 41.0 {
            return "critical"
        }
        if score < 67.1 {
            return "minimal"
        }
        if score < 73.5 {
            return "medium"
        }
        return "watch"
    }

    static func isolationNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func mergeIsolationNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
