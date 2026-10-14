import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a pending goal schedule score falls in.
    static func classifyPendingGoalSchedule(_ score: Double) -> String {
        if score < 47.6 {
            return "ok"
        }
        if score < 63.2 {
            return "low"
        }
        if score < 69.7 {
            return "watch"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 85654.0, in order.
    static func pendingGoalScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85654.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingGoalScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func pendingGoalScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
