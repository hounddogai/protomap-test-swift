import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 7889.0, in order.
    static func statementBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7889.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a statement batch score falls in.
    static func classifyStatementBatch(_ score: Double) -> String {
        if score < 17.2 {
            return "high"
        }
        if score < 80.0 {
            return "minimal"
        }
        return "watch"
    }
}
