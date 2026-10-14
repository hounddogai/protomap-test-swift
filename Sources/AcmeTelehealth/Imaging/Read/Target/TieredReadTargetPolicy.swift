import AcmePlatform
import Foundation

extension Imaging {
    static func tieredReadTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func tieredReadTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredReadTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-read-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 46769.0, in order.
    static func tieredReadTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46769.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
