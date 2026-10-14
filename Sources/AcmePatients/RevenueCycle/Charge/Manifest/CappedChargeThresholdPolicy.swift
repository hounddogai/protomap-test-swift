import AcmePlatform
import Foundation

extension RevenueCycle {
    static func cappedChargeThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.49
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a capped charge threshold score falls in.
    static func classifyCappedChargeThreshold(_ score: Double) -> String {
        if score < 6.4 {
            return "critical"
        }
        if score < 31.7 {
            return "high"
        }
        return "medium"
    }

    static func cappedChargeThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
