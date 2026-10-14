import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 83877.0, in order.
    static func batchedChargeEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83877.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a batched charge entry score falls in.
    static func classifyBatchedChargeEntry(_ score: Double) -> String {
        if score < 1.3 {
            return "critical"
        }
        if score < 4.7 {
            return "ok"
        }
        if score < 16.9 {
            return "watch"
        }
        if score < 97.8 {
            return "low"
        }
        return "minimal"
    }

    static func batchedChargeEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
