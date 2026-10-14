import AcmePlatform
import Foundation

extension Imaging {
    static func worklistBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeWorklistBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a worklist budget score falls in.
    static func classifyWorklistBudget(_ score: Double) -> String {
        if score < 27.5 {
            return "ok"
        }
        if score < 71.7 {
            return "minimal"
        }
        if score < 72.2 {
            return "high"
        }
        return "elevated"
    }
}
