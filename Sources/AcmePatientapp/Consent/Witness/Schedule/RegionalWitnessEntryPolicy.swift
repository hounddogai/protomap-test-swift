import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 46065.0, in order.
    static func regionalWitnessEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46065.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a regional witness entry score falls in.
    static func classifyRegionalWitnessEntry(_ score: Double) -> String {
        if score < 74.6 {
            return "critical"
        }
        if score < 98.8 {
            return "medium"
        }
        if score < 99.7 {
            return "minimal"
        }
        return "high"
    }
}
