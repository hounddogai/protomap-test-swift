import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 66648.0, in order.
    static func weightedAcuityPlanEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66648.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a weighted acuity plan estimate score falls in.
    static func classifyWeightedAcuityPlanEstimate(_ score: Double) -> String {
        if score < 31.3 {
            return "critical"
        }
        if score < 51.2 {
            return "watch"
        }
        if score < 51.3 {
            return "elevated"
        }
        if score < 76.8 {
            return "high"
        }
        return "medium"
    }
}
