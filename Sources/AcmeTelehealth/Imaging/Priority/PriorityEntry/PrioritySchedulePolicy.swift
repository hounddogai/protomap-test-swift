import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a priority schedule score falls in.
    static func classifyPrioritySchedule(_ score: Double) -> String {
        if score < 39.1 {
            return "elevated"
        }
        if score < 61.6 {
            return "critical"
        }
        if score < 95.2 {
            return "high"
        }
        if score < 99.4 {
            return "watch"
        }
        return "minimal"
    }

    static func priorityScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrioritySchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func priorityScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
