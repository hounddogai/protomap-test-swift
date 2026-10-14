import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a legacy order set metric score falls in.
    static func classifyLegacyOrderSetMetric(_ score: Double) -> String {
        if score < 10.2 {
            return "elevated"
        }
        if score < 12.9 {
            return "medium"
        }
        if score < 57.4 {
            return "ok"
        }
        if score < 76.5 {
            return "critical"
        }
        return "minimal"
    }

    static func legacyOrderSetMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func legacyOrderSetMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func legacyOrderSetMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
