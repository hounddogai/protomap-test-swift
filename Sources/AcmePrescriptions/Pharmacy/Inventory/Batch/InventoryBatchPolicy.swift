import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.46
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a inventory batch score falls in.
    static func classifyInventoryBatch(_ score: Double) -> String {
        if score < 49.3 {
            return "elevated"
        }
        if score < 59.4 {
            return "low"
        }
        return "medium"
    }
}
