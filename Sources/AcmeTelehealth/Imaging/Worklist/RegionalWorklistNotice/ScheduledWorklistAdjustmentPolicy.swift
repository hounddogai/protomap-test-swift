import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 23092.0, in order.
    static func scheduledWorklistAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23092.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a scheduled worklist adjustment score falls in.
    static func classifyScheduledWorklistAdjustment(_ score: Double) -> String {
        if score < 22.2 {
            return "critical"
        }
        if score < 28.8 {
            return "minimal"
        }
        if score < 59.8 {
            return "elevated"
        }
        if score < 62.5 {
            return "watch"
        }
        return "medium"
    }

    static func scheduledWorklistAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
