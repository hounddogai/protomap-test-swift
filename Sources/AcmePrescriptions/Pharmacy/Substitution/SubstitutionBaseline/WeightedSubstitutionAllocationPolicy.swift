import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeWeightedSubstitutionAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a weighted substitution allocation score falls in.
    static func classifyWeightedSubstitutionAllocation(_ score: Double) -> String {
        if score < 8.2 {
            return "elevated"
        }
        if score < 25.7 {
            return "high"
        }
        if score < 28.3 {
            return "watch"
        }
        if score < 33.2 {
            return "medium"
        }
        return "minimal"
    }

    static func weightedSubstitutionAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
