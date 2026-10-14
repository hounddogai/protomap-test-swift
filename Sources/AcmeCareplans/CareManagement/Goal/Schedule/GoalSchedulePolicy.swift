import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a goal schedule score falls in.
    static func classifyGoalSchedule(_ score: Double) -> String {
        if score < 5.2 {
            return "critical"
        }
        if score < 36.8 {
            return "low"
        }
        if score < 78.1 {
            return "medium"
        }
        if score < 79.4 {
            return "ok"
        }
        return "watch"
    }

    static func goalScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGoalSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("goal-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
