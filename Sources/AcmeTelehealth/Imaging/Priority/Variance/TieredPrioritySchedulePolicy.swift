import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a tiered priority schedule score falls in.
    static func classifyTieredPrioritySchedule(_ score: Double) -> String {
        if score < 3.2 {
            return "low"
        }
        if score < 99.0 {
            return "ok"
        }
        return "critical"
    }

    static func tieredPriorityScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredPrioritySchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-priority-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 97798.0, in order.
    static func tieredPriorityScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97798.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
