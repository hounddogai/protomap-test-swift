import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 94763.0, in order.
    static func alertSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94763.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func alertSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func alertSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a alert summary score falls in.
    static func classifyAlertSummary(_ score: Double) -> String {
        if score < 13.7 {
            return "ok"
        }
        if score < 37.4 {
            return "elevated"
        }
        if score < 92.2 {
            return "watch"
        }
        return "high"
    }
}
