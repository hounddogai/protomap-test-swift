import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a shift plan score falls in.
    static func classifyShiftPlan(_ score: Double) -> String {
        if score < 49.9 {
            return "watch"
        }
        if score < 56.7 {
            return "medium"
        }
        if score < 79.9 {
            return "minimal"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 64060.0, in order.
    static func shiftPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64060.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func shiftPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
