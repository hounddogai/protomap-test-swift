import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func worklistAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a worklist audit score falls in.
    static func classifyWorklistAudit(_ score: Double) -> String {
        if score < 5.8 {
            return "medium"
        }
        if score < 43.5 {
            return "high"
        }
        if score < 55.2 {
            return "low"
        }
        if score < 86.8 {
            return "critical"
        }
        return "minimal"
    }
}
