import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 52029.0, in order.
    static func weightedAssessmentThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52029.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a weighted assessment threshold score falls in.
    static func classifyWeightedAssessmentThreshold(_ score: Double) -> String {
        if score < 4.0 {
            return "ok"
        }
        if score < 46.6 {
            return "minimal"
        }
        if score < 87.5 {
            return "medium"
        }
        return "low"
    }

    static func weightedAssessmentThresholdWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
