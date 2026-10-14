import AcmePlatform
import Foundation

extension ClinicalOps {
    static func roundingAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a rounding adjustment score falls in.
    static func classifyRoundingAdjustment(_ score: Double) -> String {
        if score < 27.6 {
            return "ok"
        }
        if score < 32.0 {
            return "medium"
        }
        if score < 84.3 {
            return "high"
        }
        return "elevated"
    }

    static func roundingAdjustmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.2
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
