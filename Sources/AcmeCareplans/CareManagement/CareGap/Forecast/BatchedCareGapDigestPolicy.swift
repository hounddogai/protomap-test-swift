import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a batched care gap digest score falls in.
    static func classifyBatchedCareGapDigest(_ score: Double) -> String {
        if score < 10.2 {
            return "minimal"
        }
        if score < 40.8 {
            return "medium"
        }
        if score < 42.0 {
            return "watch"
        }
        return "low"
    }

    static func batchedCareGapDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
