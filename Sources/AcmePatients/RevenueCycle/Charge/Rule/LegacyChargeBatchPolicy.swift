import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a legacy charge batch score falls in.
    static func classifyLegacyChargeBatch(_ score: Double) -> String {
        if score < 38.7 {
            return "minimal"
        }
        if score < 93.6 {
            return "medium"
        }
        return "low"
    }

    static func mergeLegacyChargeBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
