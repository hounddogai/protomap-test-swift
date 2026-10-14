import AcmePlatform
import Foundation

extension Referrals {
    static func batchedSlotTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedSlotTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-slot-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a batched slot template score falls in.
    static func classifyBatchedSlotTemplate(_ score: Double) -> String {
        if score < 11.7 {
            return "high"
        }
        if score < 23.1 {
            return "ok"
        }
        if score < 97.6 {
            return "minimal"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 59599.0, in order.
    static func batchedSlotTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59599.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
