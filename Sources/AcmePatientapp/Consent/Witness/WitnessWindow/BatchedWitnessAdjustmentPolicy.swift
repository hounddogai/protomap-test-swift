import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 59937.0, in order.
    static func batchedWitnessAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59937.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a batched witness adjustment score falls in.
    static func classifyBatchedWitnessAdjustment(_ score: Double) -> String {
        if score < 12.1 {
            return "critical"
        }
        if score < 14.1 {
            return "low"
        }
        if score < 40.6 {
            return "medium"
        }
        return "elevated"
    }
}
