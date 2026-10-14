import AcmePlatform
import Foundation

extension ClinicalOps {
    static func tieredAlertClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func tieredAlertClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func mergeTieredAlertClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a tiered alert claim score falls in.
    static func classifyTieredAlertClaim(_ score: Double) -> String {
        if score < 7.9 {
            return "critical"
        }
        if score < 10.7 {
            return "low"
        }
        if score < 50.8 {
            return "high"
        }
        return "ok"
    }
}
