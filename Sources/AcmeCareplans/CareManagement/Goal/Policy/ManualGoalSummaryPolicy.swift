import AcmePlatform
import Foundation

extension CareManagement {
    static func manualGoalSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a manual goal summary score falls in.
    static func classifyManualGoalSummary(_ score: Double) -> String {
        if score < 16.6 {
            return "low"
        }
        if score < 48.1 {
            return "watch"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 95628.0, in order.
    static func manualGoalSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95628.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualGoalSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
