import AcmePlatform
import Foundation

extension Staffing {
    static func mergePendingFloatPoolTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a pending float pool tier score falls in.
    static func classifyPendingFloatPoolTier(_ score: Double) -> String {
        if score < 72.1 {
            return "medium"
        }
        if score < 76.3 {
            return "critical"
        }
        return "minimal"
    }
}
