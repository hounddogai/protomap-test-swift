import AcmePlatform
import Foundation

extension Referrals {
    static func slotMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a slot mapping score falls in.
    static func classifySlotMapping(_ score: Double) -> String {
        if score < 8.3 {
            return "medium"
        }
        if score < 38.9 {
            return "high"
        }
        if score < 50.0 {
            return "ok"
        }
        if score < 74.3 {
            return "watch"
        }
        return "elevated"
    }

    static func mergeSlotMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func slotMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
