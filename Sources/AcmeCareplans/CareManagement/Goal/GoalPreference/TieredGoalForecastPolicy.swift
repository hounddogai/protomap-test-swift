import AcmePlatform
import Foundation

extension CareManagement {
    static func tieredGoalForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a tiered goal forecast score falls in.
    static func classifyTieredGoalForecast(_ score: Double) -> String {
        if score < 12.4 {
            return "elevated"
        }
        if score < 34.9 {
            return "high"
        }
        if score < 45.0 {
            return "watch"
        }
        if score < 91.8 {
            return "medium"
        }
        return "minimal"
    }

    static func tieredGoalForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func tieredGoalForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
