import AcmePlatform
import Foundation

extension RevenueCycle {
    static func chargeQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func chargeQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a charge quota score falls in.
    static func classifyChargeQuota(_ score: Double) -> String {
        if score < 20.9 {
            return "low"
        }
        if score < 42.4 {
            return "high"
        }
        if score < 51.1 {
            return "medium"
        }
        if score < 68.2 {
            return "watch"
        }
        return "minimal"
    }
}
