import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeBatchedRoundingMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a batched rounding mapping score falls in.
    static func classifyBatchedRoundingMapping(_ score: Double) -> String {
        if score < 41.8 {
            return "ok"
        }
        if score < 76.8 {
            return "elevated"
        }
        if score < 79.4 {
            return "critical"
        }
        if score < 80.4 {
            return "medium"
        }
        return "low"
    }
}
