import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func overtimeSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a overtime slot score falls in.
    static func classifyOvertimeSlot(_ score: Double) -> String {
        if score < 30.7 {
            return "watch"
        }
        if score < 43.4 {
            return "ok"
        }
        if score < 51.4 {
            return "elevated"
        }
        if score < 68.4 {
            return "critical"
        }
        return "medium"
    }

    static func overtimeSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
