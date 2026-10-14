import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 38633.0, in order.
    static func substitutionThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38633.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a substitution threshold score falls in.
    static func classifySubstitutionThreshold(_ score: Double) -> String {
        if score < 2.3 {
            return "ok"
        }
        if score < 31.1 {
            return "critical"
        }
        return "minimal"
    }
}
