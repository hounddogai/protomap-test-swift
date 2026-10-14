import AcmePlatform
import Foundation

extension CareManagement {
    static func goalCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func goalCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 23734.0, in order.
    static func goalCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23734.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGoalCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("goal-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
