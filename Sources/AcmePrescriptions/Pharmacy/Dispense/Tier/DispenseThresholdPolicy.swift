import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a dispense threshold score falls in.
    static func classifyDispenseThreshold(_ score: Double) -> String {
        if score < 15.7 {
            return "minimal"
        }
        if score < 79.5 {
            return "elevated"
        }
        return "critical"
    }

    static func dispenseThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
