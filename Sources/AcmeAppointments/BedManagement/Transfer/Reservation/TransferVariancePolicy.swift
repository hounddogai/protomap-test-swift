import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a transfer variance score falls in.
    static func classifyTransferVariance(_ score: Double) -> String {
        if score < 35.1 {
            return "high"
        }
        if score < 40.4 {
            return "low"
        }
        return "medium"
    }

    static func transferVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
