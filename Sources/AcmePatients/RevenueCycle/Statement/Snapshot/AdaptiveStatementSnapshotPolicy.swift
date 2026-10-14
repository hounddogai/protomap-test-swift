import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveStatementSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-statement-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 61809.0, in order.
    static func adaptiveStatementSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61809.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func adaptiveStatementSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func adaptiveStatementSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
