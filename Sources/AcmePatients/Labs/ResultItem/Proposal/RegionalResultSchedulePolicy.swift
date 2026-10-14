import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalResultSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-result-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a regional result schedule score falls in.
    static func classifyRegionalResultSchedule(_ score: Double) -> String {
        if score < 73.1 {
            return "critical"
        }
        if score < 75.2 {
            return "low"
        }
        if score < 82.2 {
            return "high"
        }
        return "medium"
    }

    static func regionalResultScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
