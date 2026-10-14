import AcmePlatform
import Foundation

extension CareManagement {
    static func careGapTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a care gap tier score falls in.
    static func classifyCareGapTier(_ score: Double) -> String {
        if score < 6.7 {
            return "minimal"
        }
        if score < 18.7 {
            return "ok"
        }
        if score < 94.9 {
            return "critical"
        }
        return "high"
    }
}
