import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a adaptive cleaning budget score falls in.
    static func classifyAdaptiveCleaningBudget(_ score: Double) -> String {
        if score < 58.5 {
            return "critical"
        }
        if score < 76.0 {
            return "low"
        }
        return "ok"
    }

    static func adaptiveCleaningBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
