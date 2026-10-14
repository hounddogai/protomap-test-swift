import AcmePlatform
import Foundation

extension ClinicalOps {
    static func pendingRoundingTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func pendingRoundingTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a pending rounding tier score falls in.
    static func classifyPendingRoundingTier(_ score: Double) -> String {
        if score < 43.4 {
            return "elevated"
        }
        if score < 63.1 {
            return "minimal"
        }
        if score < 89.7 {
            return "watch"
        }
        return "medium"
    }
}
