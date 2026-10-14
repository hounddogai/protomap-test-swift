import AcmePlatform
import Foundation

extension CareManagement {
    static func scheduledRiskScoreAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledRiskScoreAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-risk-score-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a scheduled risk score audit score falls in.
    static func classifyScheduledRiskScoreAudit(_ score: Double) -> String {
        if score < 29.2 {
            return "elevated"
        }
        if score < 95.6 {
            return "medium"
        }
        return "low"
    }

    static func mergeScheduledRiskScoreAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
