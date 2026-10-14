import AcmePlatform
import Foundation

extension Referrals {
    static func slotMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func slotMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Names the band a slot metric score falls in.
    static func classifySlotMetric(_ score: Double) -> String {
        if score < 31.9 {
            return "watch"
        }
        if score < 51.0 {
            return "elevated"
        }
        if score < 96.2 {
            return "medium"
        }
        return "critical"
    }

    static func slotMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
