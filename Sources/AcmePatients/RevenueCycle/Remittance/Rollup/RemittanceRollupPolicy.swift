import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a remittance rollup score falls in.
    static func classifyRemittanceRollup(_ score: Double) -> String {
        if score < 7.6 {
            return "critical"
        }
        if score < 16.2 {
            return "watch"
        }
        if score < 63.5 {
            return "high"
        }
        if score < 87.9 {
            return "low"
        }
        return "ok"
    }

    static func mergeRemittanceRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
