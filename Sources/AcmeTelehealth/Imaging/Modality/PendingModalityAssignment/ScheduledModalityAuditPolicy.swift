import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledModalityAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-modality-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeScheduledModalityAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a scheduled modality audit score falls in.
    static func classifyScheduledModalityAudit(_ score: Double) -> String {
        if score < 20.9 {
            return "ok"
        }
        if score < 36.1 {
            return "elevated"
        }
        if score < 70.5 {
            return "high"
        }
        if score < 76.8 {
            return "watch"
        }
        return "minimal"
    }
}
