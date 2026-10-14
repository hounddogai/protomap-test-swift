import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a network baseline score falls in.
    static func classifyNetworkBaseline(_ score: Double) -> String {
        if score < 41.1 {
            return "high"
        }
        if score < 42.5 {
            return "critical"
        }
        return "low"
    }

    static func networkBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
