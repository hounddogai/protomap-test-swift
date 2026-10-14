import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedOvertimePlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-overtime-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a batched overtime plan score falls in.
    static func classifyBatchedOvertimePlan(_ score: Double) -> String {
        if score < 10.2 {
            return "minimal"
        }
        if score < 14.4 {
            return "high"
        }
        if score < 61.7 {
            return "watch"
        }
        return "low"
    }
}
