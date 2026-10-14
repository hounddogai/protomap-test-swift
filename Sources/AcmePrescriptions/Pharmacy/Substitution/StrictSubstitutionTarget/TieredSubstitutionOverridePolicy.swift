import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeTieredSubstitutionOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a tiered substitution override score falls in.
    static func classifyTieredSubstitutionOverride(_ score: Double) -> String {
        if score < 6.0 {
            return "elevated"
        }
        if score < 76.7 {
            return "ok"
        }
        return "high"
    }

    static func tieredSubstitutionOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
