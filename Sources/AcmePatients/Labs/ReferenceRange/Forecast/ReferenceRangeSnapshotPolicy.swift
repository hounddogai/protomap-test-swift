import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 89556.0, in order.
    static func referenceRangeSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89556.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeReferenceRangeSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferenceRangeSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("reference-range-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func referenceRangeSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
