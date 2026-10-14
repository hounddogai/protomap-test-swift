import AcmePlatform
import Foundation

extension Labs {
    static func mergeBatchedAccessionPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedAccessionPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-accession-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedAccessionPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 66516.0, in order.
    static func batchedAccessionPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66516.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
