import AcmePlatform
import Foundation

extension Labs {
    static func pendingResultMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a pending result metric score falls in.
    static func classifyPendingResultMetric(_ score: Double) -> String {
        if score < 23.8 {
            return "minimal"
        }
        if score < 70.3 {
            return "high"
        }
        return "medium"
    }
}
