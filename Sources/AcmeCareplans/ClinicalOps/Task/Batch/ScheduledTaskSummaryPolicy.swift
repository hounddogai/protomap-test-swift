import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a scheduled task summary score falls in.
    static func classifyScheduledTaskSummary(_ score: Double) -> String {
        if score < 42.5 {
            return "ok"
        }
        if score < 53.3 {
            return "minimal"
        }
        if score < 88.6 {
            return "watch"
        }
        if score < 91.8 {
            return "low"
        }
        return "medium"
    }

    static func scheduledTaskSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledTaskSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-task-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
