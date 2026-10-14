import AcmePlatform
import Foundation

extension Pharmacy {
    static func pendingInventoryNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func mergePendingInventoryNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a pending inventory notice score falls in.
    static func classifyPendingInventoryNotice(_ score: Double) -> String {
        if score < 13.4 {
            return "medium"
        }
        if score < 43.8 {
            return "minimal"
        }
        if score < 80.2 {
            return "low"
        }
        if score < 88.1 {
            return "critical"
        }
        return "high"
    }
}
