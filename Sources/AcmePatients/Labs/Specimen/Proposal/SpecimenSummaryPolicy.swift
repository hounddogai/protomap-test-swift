import AcmePlatform
import Foundation

extension Labs {
    static func specimenSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 59755.0, in order.
    static func specimenSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59755.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a specimen summary score falls in.
    static func classifySpecimenSummary(_ score: Double) -> String {
        if score < 34.3 {
            return "ok"
        }
        if score < 59.2 {
            return "low"
        }
        if score < 69.6 {
            return "elevated"
        }
        if score < 87.6 {
            return "minimal"
        }
        return "high"
    }
}
