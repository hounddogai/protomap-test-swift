import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a handoff budget score falls in.
    static func classifyHandoffBudget(_ score: Double) -> String {
        if score < 21.5 {
            return "minimal"
        }
        if score < 49.3 {
            return "high"
        }
        if score < 51.2 {
            return "ok"
        }
        if score < 71.6 {
            return "medium"
        }
        return "watch"
    }

    static func mergeHandoffBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
