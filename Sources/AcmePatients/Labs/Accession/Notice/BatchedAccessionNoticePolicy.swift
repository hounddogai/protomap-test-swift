import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedAccessionNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-accession-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a batched accession notice score falls in.
    static func classifyBatchedAccessionNotice(_ score: Double) -> String {
        if score < 3.5 {
            return "elevated"
        }
        if score < 19.8 {
            return "watch"
        }
        if score < 28.9 {
            return "medium"
        }
        if score < 89.6 {
            return "high"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 7701.0, in order.
    static func batchedAccessionNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7701.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
