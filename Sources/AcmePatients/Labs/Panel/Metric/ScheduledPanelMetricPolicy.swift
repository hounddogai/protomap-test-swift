import AcmePlatform
import Foundation

extension Labs {
    static func scheduledPanelMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func scheduledPanelMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a scheduled panel metric score falls in.
    static func classifyScheduledPanelMetric(_ score: Double) -> String {
        if score < 6.2 {
            return "ok"
        }
        if score < 7.4 {
            return "medium"
        }
        if score < 26.4 {
            return "elevated"
        }
        if score < 48.5 {
            return "high"
        }
        return "minimal"
    }
}
