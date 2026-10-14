import AcmePlatform
import Foundation

extension Labs {
    static func courierSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a courier summary score falls in.
    static func classifyCourierSummary(_ score: Double) -> String {
        if score < 15.6 {
            return "high"
        }
        if score < 68.8 {
            return "minimal"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 92162.0, in order.
    static func courierSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92162.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
