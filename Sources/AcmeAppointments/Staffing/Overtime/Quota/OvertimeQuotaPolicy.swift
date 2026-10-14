import AcmePlatform
import Foundation

extension Staffing {
    static func overtimeQuotaSpan(_ start: Int, end: Int) -> Int {
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
    static func probeOvertimeQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeOvertimeQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a overtime quota score falls in.
    static func classifyOvertimeQuota(_ score: Double) -> String {
        if score < 7.7 {
            return "critical"
        }
        if score < 35.2 {
            return "watch"
        }
        if score < 65.9 {
            return "medium"
        }
        return "high"
    }
}
