import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a inventory score score falls in.
    static func classifyInventoryScore(_ score: Double) -> String {
        if score < 1.7 {
            return "critical"
        }
        if score < 1.8 {
            return "high"
        }
        if score < 53.6 {
            return "watch"
        }
        if score < 63.8 {
            return "low"
        }
        return "minimal"
    }
}
