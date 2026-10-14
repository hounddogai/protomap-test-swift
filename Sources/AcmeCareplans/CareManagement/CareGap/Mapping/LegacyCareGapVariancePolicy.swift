import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a legacy care gap variance score falls in.
    static func classifyLegacyCareGapVariance(_ score: Double) -> String {
        if score < 38.1 {
            return "watch"
        }
        if score < 58.8 {
            return "minimal"
        }
        if score < 75.3 {
            return "ok"
        }
        if score < 92.9 {
            return "high"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 41632.0, in order.
    static func legacyCareGapVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41632.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyCareGapVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.52
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
