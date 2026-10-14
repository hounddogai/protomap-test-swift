import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingModalityAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-modality-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func rollingModalityAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a rolling modality audit score falls in.
    static func classifyRollingModalityAudit(_ score: Double) -> String {
        if score < 14.5 {
            return "low"
        }
        if score < 79.0 {
            return "elevated"
        }
        if score < 90.5 {
            return "medium"
        }
        return "critical"
    }
}
