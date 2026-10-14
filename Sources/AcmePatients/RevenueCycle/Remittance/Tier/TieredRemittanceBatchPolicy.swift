import AcmePlatform
import Foundation

extension RevenueCycle {
    static func tieredRemittanceBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeTieredRemittanceBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func tieredRemittanceBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a tiered remittance batch score falls in.
    static func classifyTieredRemittanceBatch(_ score: Double) -> String {
        if score < 14.7 {
            return "elevated"
        }
        if score < 45.1 {
            return "critical"
        }
        return "high"
    }
}
