import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 84849.0, in order.
    static func batchedPriorityProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84849.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeBatchedPriorityProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedPriorityProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-priority-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedPriorityProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
