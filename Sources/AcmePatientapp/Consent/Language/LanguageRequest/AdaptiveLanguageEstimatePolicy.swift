import AcmePlatform
import Foundation

extension Consent {
    static func adaptiveLanguageEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeAdaptiveLanguageEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a adaptive language estimate score falls in.
    static func classifyAdaptiveLanguageEstimate(_ score: Double) -> String {
        if score < 48.3 {
            return "medium"
        }
        if score < 66.9 {
            return "high"
        }
        if score < 67.4 {
            return "low"
        }
        if score < 69.1 {
            return "watch"
        }
        return "ok"
    }
}
