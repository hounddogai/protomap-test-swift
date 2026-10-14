import AcmePlatform
import Foundation

extension Staffing {
    static func rollingShiftMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func rollingShiftMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rolling shift metric score falls in.
    static func classifyRollingShiftMetric(_ score: Double) -> String {
        if score < 41.5 {
            return "critical"
        }
        if score < 45.7 {
            return "watch"
        }
        if score < 64.7 {
            return "medium"
        }
        return "minimal"
    }
}
