import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a tiered charge variance score falls in.
    static func classifyTieredChargeVariance(_ score: Double) -> String {
        if score < 17.9 {
            return "critical"
        }
        if score < 63.4 {
            return "medium"
        }
        if score < 93.1 {
            return "elevated"
        }
        return "ok"
    }

    static func mergeTieredChargeVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
