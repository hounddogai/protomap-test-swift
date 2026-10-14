import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 58605.0, in order.
    static func globalReferenceRangeSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58605.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func globalReferenceRangeSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalReferenceRangeSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-reference-range-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalReferenceRangeSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
