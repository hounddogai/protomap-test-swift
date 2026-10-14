import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a default assessment estimate score falls in.
    static func classifyDefaultAssessmentEstimate(_ score: Double) -> String {
        if score < 21.5 {
            return "ok"
        }
        if score < 44.5 {
            return "low"
        }
        if score < 70.0 {
            return "critical"
        }
        if score < 90.3 {
            return "elevated"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 13703.0, in order.
    static func defaultAssessmentEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13703.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
