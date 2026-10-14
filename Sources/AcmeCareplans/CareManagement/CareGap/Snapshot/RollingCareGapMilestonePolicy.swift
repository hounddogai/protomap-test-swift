import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingCareGapMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-care-gap-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingCareGapMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 97808.0, in order.
    static func rollingCareGapMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97808.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rolling care gap milestone score falls in.
    static func classifyRollingCareGapMilestone(_ score: Double) -> String {
        if score < 4.9 {
            return "critical"
        }
        if score < 33.7 {
            return "high"
        }
        if score < 48.0 {
            return "low"
        }
        return "ok"
    }
}
