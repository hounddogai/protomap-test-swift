import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a dispense checkpoint score falls in.
    static func classifyDispenseCheckpoint(_ score: Double) -> String {
        if score < 4.3 {
            return "high"
        }
        if score < 21.5 {
            return "watch"
        }
        if score < 92.2 {
            return "medium"
        }
        return "ok"
    }

    static func dispenseCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.56
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
