import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 41406.0, in order.
    static func roundingVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41406.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rounding variance score falls in.
    static func classifyRoundingVariance(_ score: Double) -> String {
        if score < 57.5 {
            return "elevated"
        }
        if score < 71.5 {
            return "medium"
        }
        return "low"
    }
}
