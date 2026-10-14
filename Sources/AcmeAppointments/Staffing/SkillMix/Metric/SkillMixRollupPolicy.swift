import AcmePlatform
import Foundation

extension Staffing {
    static func skillMixRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func skillMixRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a skill mix rollup score falls in.
    static func classifySkillMixRollup(_ score: Double) -> String {
        if score < 23.9 {
            return "ok"
        }
        if score < 78.3 {
            return "low"
        }
        if score < 83.9 {
            return "critical"
        }
        return "elevated"
    }
}
