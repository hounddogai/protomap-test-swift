import AcmePlatform
import Foundation

extension Referrals {
    static func regionalSlotBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeRegionalSlotBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a regional slot batch score falls in.
    static func classifyRegionalSlotBatch(_ score: Double) -> String {
        if score < 5.6 {
            return "medium"
        }
        if score < 7.1 {
            return "low"
        }
        if score < 9.0 {
            return "minimal"
        }
        if score < 74.1 {
            return "watch"
        }
        return "critical"
    }
}
