import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeAdaptiveInventoryAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a adaptive inventory audit score falls in.
    static func classifyAdaptiveInventoryAudit(_ score: Double) -> String {
        if score < 1.2 {
            return "minimal"
        }
        if score < 58.7 {
            return "high"
        }
        if score < 61.0 {
            return "watch"
        }
        if score < 76.4 {
            return "critical"
        }
        return "ok"
    }
}
