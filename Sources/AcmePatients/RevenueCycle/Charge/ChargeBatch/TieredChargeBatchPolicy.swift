import AcmePlatform
import Foundation

extension RevenueCycle {
    static func tieredChargeBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.03
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a tiered charge batch score falls in.
    static func classifyTieredChargeBatch(_ score: Double) -> String {
        if score < 3.9 {
            return "high"
        }
        if score < 14.5 {
            return "low"
        }
        if score < 24.1 {
            return "medium"
        }
        if score < 46.3 {
            return "critical"
        }
        return "minimal"
    }
}
