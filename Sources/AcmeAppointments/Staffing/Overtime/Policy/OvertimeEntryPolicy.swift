import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 66386.0, in order.
    static func overtimeEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66386.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func overtimeEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a overtime entry score falls in.
    static func classifyOvertimeEntry(_ score: Double) -> String {
        if score < 13.8 {
            return "ok"
        }
        if score < 55.3 {
            return "low"
        }
        if score < 99.3 {
            return "critical"
        }
        return "watch"
    }
}
