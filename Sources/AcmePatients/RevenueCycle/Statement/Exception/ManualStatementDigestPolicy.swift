import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 12633.0, in order.
    static func manualStatementDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12633.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual statement digest score falls in.
    static func classifyManualStatementDigest(_ score: Double) -> String {
        if score < 27.4 {
            return "minimal"
        }
        if score < 86.5 {
            return "high"
        }
        if score < 87.9 {
            return "low"
        }
        return "elevated"
    }
}
