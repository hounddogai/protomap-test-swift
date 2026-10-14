import AcmePlatform
import Foundation

extension Pharmacy {
    static func dispenseRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispenseRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 900.0, in order.
    static func dispenseRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 900.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func dispenseRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.49
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
