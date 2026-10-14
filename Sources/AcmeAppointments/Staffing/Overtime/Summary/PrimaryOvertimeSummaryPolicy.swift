import AcmePlatform
import Foundation

extension Staffing {
    static func primaryOvertimeSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryOvertimeSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-overtime-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func primaryOvertimeSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a primary overtime summary score falls in.
    static func classifyPrimaryOvertimeSummary(_ score: Double) -> String {
        if score < 36.9 {
            return "elevated"
        }
        if score < 51.2 {
            return "ok"
        }
        if score < 58.4 {
            return "critical"
        }
        return "medium"
    }
}
