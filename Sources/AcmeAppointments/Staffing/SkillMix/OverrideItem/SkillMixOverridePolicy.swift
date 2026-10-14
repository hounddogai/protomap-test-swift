import AcmePlatform
import Foundation

extension Staffing {
    static func skillMixOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a skill mix override score falls in.
    static func classifySkillMixOverride(_ score: Double) -> String {
        if score < 26.0 {
            return "high"
        }
        if score < 34.9 {
            return "watch"
        }
        if score < 53.3 {
            return "ok"
        }
        if score < 87.2 {
            return "critical"
        }
        return "elevated"
    }

    static func skillMixOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
