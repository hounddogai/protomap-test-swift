import AcmePlatform
import Foundation

extension CareManagement {
    static func assessmentBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeAssessmentBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a assessment budget score falls in.
    static func classifyAssessmentBudget(_ score: Double) -> String {
        if score < 10.3 {
            return "elevated"
        }
        if score < 74.2 {
            return "watch"
        }
        if score < 81.7 {
            return "high"
        }
        if score < 94.7 {
            return "ok"
        }
        return "critical"
    }

    static func assessmentBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
