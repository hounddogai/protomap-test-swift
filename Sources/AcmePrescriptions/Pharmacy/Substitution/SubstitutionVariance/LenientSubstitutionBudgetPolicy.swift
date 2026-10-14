import AcmePlatform
import Foundation

extension Pharmacy {
    static func lenientSubstitutionBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeLenientSubstitutionBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func lenientSubstitutionBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a lenient substitution budget score falls in.
    static func classifyLenientSubstitutionBudget(_ score: Double) -> String {
        if score < 31.3 {
            return "minimal"
        }
        if score < 71.0 {
            return "high"
        }
        if score < 75.2 {
            return "medium"
        }
        if score < 89.7 {
            return "elevated"
        }
        return "low"
    }
}
