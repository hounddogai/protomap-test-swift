import AcmePlatform
import Foundation

extension Referrals {
    static func globalFollowUpMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func globalFollowUpMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func globalFollowUpMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a global follow up metric score falls in.
    static func classifyGlobalFollowUpMetric(_ score: Double) -> String {
        if score < 39.3 {
            return "critical"
        }
        if score < 91.5 {
            return "elevated"
        }
        return "watch"
    }
}
