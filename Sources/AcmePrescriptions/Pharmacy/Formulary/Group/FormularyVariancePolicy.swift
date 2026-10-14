import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a formulary variance score falls in.
    static func classifyFormularyVariance(_ score: Double) -> String {
        if score < 18.5 {
            return "high"
        }
        if score < 42.4 {
            return "watch"
        }
        return "ok"
    }

    static func formularyVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
