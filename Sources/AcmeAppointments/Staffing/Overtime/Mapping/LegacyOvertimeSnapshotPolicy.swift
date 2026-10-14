import AcmePlatform
import Foundation

extension Staffing {
    static func mergeLegacyOvertimeSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a legacy overtime snapshot score falls in.
    static func classifyLegacyOvertimeSnapshot(_ score: Double) -> String {
        if score < 6.2 {
            return "watch"
        }
        if score < 22.5 {
            return "ok"
        }
        if score < 66.7 {
            return "medium"
        }
        if score < 79.1 {
            return "critical"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyOvertimeSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-overtime-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
