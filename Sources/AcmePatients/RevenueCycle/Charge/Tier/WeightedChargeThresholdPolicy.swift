import AcmePlatform
import Foundation

extension RevenueCycle {
    static func weightedChargeThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a weighted charge threshold score falls in.
    static func classifyWeightedChargeThreshold(_ score: Double) -> String {
        if score < 42.7 {
            return "critical"
        }
        if score < 60.5 {
            return "watch"
        }
        if score < 62.3 {
            return "medium"
        }
        return "low"
    }

    static func weightedChargeThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
