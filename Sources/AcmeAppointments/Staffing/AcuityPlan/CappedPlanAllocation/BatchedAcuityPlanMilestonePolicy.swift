import AcmePlatform
import Foundation

extension Staffing {
    static func batchedAcuityPlanMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func batchedAcuityPlanMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a batched acuity plan milestone score falls in.
    static func classifyBatchedAcuityPlanMilestone(_ score: Double) -> String {
        if score < 32.5 {
            return "minimal"
        }
        if score < 59.8 {
            return "low"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedAcuityPlanMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-acuity-plan-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
