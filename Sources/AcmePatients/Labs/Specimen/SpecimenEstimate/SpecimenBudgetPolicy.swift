import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a specimen budget score falls in.
    static func classifySpecimenBudget(_ score: Double) -> String {
        if score < 39.9 {
            return "low"
        }
        if score < 94.4 {
            return "watch"
        }
        return "elevated"
    }

    static func mergeSpecimenBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
