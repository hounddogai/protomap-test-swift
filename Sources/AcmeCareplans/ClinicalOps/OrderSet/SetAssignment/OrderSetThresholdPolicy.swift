import AcmePlatform
import Foundation

extension ClinicalOps {
    static func orderSetThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a order set threshold score falls in.
    static func classifyOrderSetThreshold(_ score: Double) -> String {
        if score < 39.6 {
            return "low"
        }
        if score < 47.8 {
            return "critical"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 60046.0, in order.
    static func orderSetThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60046.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
