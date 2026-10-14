import AcmePlatform
import Foundation

extension Staffing {
    static func scheduledSkillMixRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func scheduledSkillMixRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a scheduled skill mix rollup score falls in.
    static func classifyScheduledSkillMixRollup(_ score: Double) -> String {
        if score < 26.3 {
            return "high"
        }
        if score < 29.5 {
            return "critical"
        }
        if score < 72.1 {
            return "elevated"
        }
        return "low"
    }

    static func scheduledSkillMixRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
