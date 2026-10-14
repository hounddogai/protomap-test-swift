import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 64547.0, in order.
    static func batchedClaimTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64547.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a batched claim target score falls in.
    static func classifyBatchedClaimTarget(_ score: Double) -> String {
        if score < 12.3 {
            return "elevated"
        }
        if score < 57.1 {
            return "watch"
        }
        if score < 67.6 {
            return "high"
        }
        if score < 67.8 {
            return "medium"
        }
        return "low"
    }
}
