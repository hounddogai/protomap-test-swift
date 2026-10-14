import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a adaptive handoff request score falls in.
    static func classifyAdaptiveHandoffRequest(_ score: Double) -> String {
        if score < 55.5 {
            return "elevated"
        }
        if score < 91.6 {
            return "medium"
        }
        return "high"
    }

    static func adaptiveHandoffRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.95
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
