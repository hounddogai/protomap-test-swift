import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a rolling witness entry score falls in.
    static func classifyRollingWitnessEntry(_ score: Double) -> String {
        if score < 27.7 {
            return "elevated"
        }
        if score < 35.1 {
            return "low"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 19432.0, in order.
    static func rollingWitnessEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19432.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
