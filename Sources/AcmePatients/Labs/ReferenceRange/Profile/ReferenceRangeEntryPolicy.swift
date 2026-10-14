import AcmePlatform
import Foundation

extension Labs {
    static func mergeReferenceRangeEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a reference range entry score falls in.
    static func classifyReferenceRangeEntry(_ score: Double) -> String {
        if score < 18.6 {
            return "critical"
        }
        if score < 75.5 {
            return "minimal"
        }
        return "high"
    }

    static func referenceRangeEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
