import AcmePlatform
import Foundation

extension Staffing {
    static func lenientSkillMixAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergeLenientSkillMixAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func lenientSkillMixAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a lenient skill mix assignment score falls in.
    static func classifyLenientSkillMixAssignment(_ score: Double) -> String {
        if score < 18.9 {
            return "high"
        }
        if score < 34.1 {
            return "low"
        }
        if score < 53.8 {
            return "elevated"
        }
        if score < 87.6 {
            return "medium"
        }
        return "watch"
    }
}
