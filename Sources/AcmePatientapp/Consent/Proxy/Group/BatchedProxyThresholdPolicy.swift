import AcmePlatform
import Foundation

extension Consent {
    static func mergeBatchedProxyThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a batched proxy threshold score falls in.
    static func classifyBatchedProxyThreshold(_ score: Double) -> String {
        if score < 21.9 {
            return "low"
        }
        if score < 32.3 {
            return "high"
        }
        if score < 48.9 {
            return "minimal"
        }
        return "medium"
    }
}
