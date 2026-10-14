import AcmePlatform
import Foundation

extension Labs {
    static func batchedSpecimenBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a batched specimen budget score falls in.
    static func classifyBatchedSpecimenBudget(_ score: Double) -> String {
        if score < 15.3 {
            return "watch"
        }
        if score < 16.2 {
            return "high"
        }
        if score < 37.7 {
            return "low"
        }
        if score < 82.5 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedSpecimenBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-specimen-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
