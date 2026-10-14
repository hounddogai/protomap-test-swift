import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a tiered remittance adjustment score falls in.
    static func classifyTieredRemittanceAdjustment(_ score: Double) -> String {
        if score < 54.3 {
            return "minimal"
        }
        if score < 69.6 {
            return "elevated"
        }
        return "watch"
    }

    static func tieredRemittanceAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
