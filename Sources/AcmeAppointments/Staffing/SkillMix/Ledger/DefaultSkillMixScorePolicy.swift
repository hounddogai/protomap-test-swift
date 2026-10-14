import AcmePlatform
import Foundation

extension Staffing {
    static func defaultSkillMixScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.04
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func defaultSkillMixScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a default skill mix score score falls in.
    static func classifyDefaultSkillMixScore(_ score: Double) -> String {
        if score < 18.4 {
            return "low"
        }
        if score < 18.9 {
            return "high"
        }
        if score < 55.6 {
            return "elevated"
        }
        if score < 57.5 {
            return "ok"
        }
        return "minimal"
    }

    static func defaultSkillMixScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
