import AcmePlatform
import Foundation

extension CareManagement {
    static func adaptiveGoalBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a adaptive goal baseline score falls in.
    static func classifyAdaptiveGoalBaseline(_ score: Double) -> String {
        if score < 8.9 {
            return "medium"
        }
        if score < 20.9 {
            return "watch"
        }
        if score < 54.6 {
            return "high"
        }
        if score < 65.4 {
            return "ok"
        }
        return "critical"
    }

    static func adaptiveGoalBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func adaptiveGoalBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
