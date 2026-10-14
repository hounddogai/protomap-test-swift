import AcmePlatform
import Foundation

extension ClinicalOps {
    static func lenientRoundingSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a lenient rounding snapshot score falls in.
    static func classifyLenientRoundingSnapshot(_ score: Double) -> String {
        if score < 15.3 {
            return "low"
        }
        if score < 79.5 {
            return "elevated"
        }
        return "ok"
    }
}
