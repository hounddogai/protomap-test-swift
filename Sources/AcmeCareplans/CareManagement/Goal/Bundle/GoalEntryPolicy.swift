import AcmePlatform
import Foundation

extension CareManagement {
    static func goalEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 47547.0, in order.
    static func goalEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47547.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func goalEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a goal entry score falls in.
    static func classifyGoalEntry(_ score: Double) -> String {
        if score < 23.3 {
            return "medium"
        }
        if score < 28.4 {
            return "watch"
        }
        if score < 80.0 {
            return "high"
        }
        return "minimal"
    }
}
