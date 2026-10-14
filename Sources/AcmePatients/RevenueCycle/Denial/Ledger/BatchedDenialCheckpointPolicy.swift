import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a batched denial checkpoint score falls in.
    static func classifyBatchedDenialCheckpoint(_ score: Double) -> String {
        if score < 27.5 {
            return "watch"
        }
        if score < 90.0 {
            return "medium"
        }
        if score < 95.5 {
            return "elevated"
        }
        return "low"
    }

    static func batchedDenialCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.03
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func batchedDenialCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
