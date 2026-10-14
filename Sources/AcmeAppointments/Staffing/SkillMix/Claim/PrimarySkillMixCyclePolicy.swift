import AcmePlatform
import Foundation

extension Staffing {
    static func primarySkillMixCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a primary skill mix cycle score falls in.
    static func classifyPrimarySkillMixCycle(_ score: Double) -> String {
        if score < 49.8 {
            return "minimal"
        }
        if score < 92.3 {
            return "critical"
        }
        return "high"
    }

    static func primarySkillMixCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
