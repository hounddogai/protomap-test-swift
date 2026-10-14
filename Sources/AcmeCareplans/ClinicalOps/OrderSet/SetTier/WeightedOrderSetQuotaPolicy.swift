import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeWeightedOrderSetQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a weighted order set quota score falls in.
    static func classifyWeightedOrderSetQuota(_ score: Double) -> String {
        if score < 16.6 {
            return "high"
        }
        if score < 17.7 {
            return "watch"
        }
        if score < 34.1 {
            return "critical"
        }
        return "elevated"
    }
}
