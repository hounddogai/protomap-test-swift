import AcmePlatform
import Foundation

extension Pharmacy {
    static func globalFormularyBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a global formulary baseline score falls in.
    static func classifyGlobalFormularyBaseline(_ score: Double) -> String {
        if score < 3.8 {
            return "medium"
        }
        if score < 61.7 {
            return "high"
        }
        if score < 96.3 {
            return "critical"
        }
        return "minimal"
    }
}
