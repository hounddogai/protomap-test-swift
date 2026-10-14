import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a pending reference range override score falls in.
    static func classifyPendingReferenceRangeOverride(_ score: Double) -> String {
        if score < 22.0 {
            return "elevated"
        }
        if score < 27.5 {
            return "low"
        }
        if score < 29.5 {
            return "high"
        }
        if score < 72.0 {
            return "critical"
        }
        return "watch"
    }

    static func pendingReferenceRangeOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergePendingReferenceRangeOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
