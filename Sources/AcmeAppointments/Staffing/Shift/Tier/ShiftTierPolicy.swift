import AcmePlatform
import Foundation

extension Staffing {
    static func mergeShiftTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a shift tier score falls in.
    static func classifyShiftTier(_ score: Double) -> String {
        if score < 12.0 {
            return "high"
        }
        if score < 27.5 {
            return "low"
        }
        if score < 42.2 {
            return "critical"
        }
        return "ok"
    }
}
