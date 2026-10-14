import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a strict dispense request score falls in.
    static func classifyStrictDispenseRequest(_ score: Double) -> String {
        if score < 24.1 {
            return "ok"
        }
        if score < 96.3 {
            return "elevated"
        }
        return "critical"
    }

    static func strictDispenseRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
