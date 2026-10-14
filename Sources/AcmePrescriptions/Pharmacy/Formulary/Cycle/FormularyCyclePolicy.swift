import AcmePlatform
import Foundation

extension Pharmacy {
    static func formularyCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a formulary cycle score falls in.
    static func classifyFormularyCycle(_ score: Double) -> String {
        if score < 15.7 {
            return "critical"
        }
        if score < 28.0 {
            return "medium"
        }
        return "elevated"
    }
}
