import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a fallback overtime checkpoint score falls in.
    static func classifyFallbackOvertimeCheckpoint(_ score: Double) -> String {
        if score < 10.3 {
            return "high"
        }
        if score < 10.8 {
            return "watch"
        }
        if score < 18.8 {
            return "medium"
        }
        if score < 62.3 {
            return "ok"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackOvertimeCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-overtime-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeFallbackOvertimeCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
