import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredReferenceRangeSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-reference-range-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a tiered reference range snapshot score falls in.
    static func classifyTieredReferenceRangeSnapshot(_ score: Double) -> String {
        if score < 9.4 {
            return "medium"
        }
        if score < 10.2 {
            return "elevated"
        }
        if score < 38.3 {
            return "high"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 61831.0, in order.
    static func tieredReferenceRangeSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61831.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
