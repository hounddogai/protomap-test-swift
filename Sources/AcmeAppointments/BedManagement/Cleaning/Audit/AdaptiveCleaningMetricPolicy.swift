import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveCleaningMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a adaptive cleaning metric score falls in.
    static func classifyAdaptiveCleaningMetric(_ score: Double) -> String {
        if score < 15.9 {
            return "critical"
        }
        if score < 17.3 {
            return "medium"
        }
        if score < 36.0 {
            return "high"
        }
        if score < 97.7 {
            return "low"
        }
        return "ok"
    }
}
