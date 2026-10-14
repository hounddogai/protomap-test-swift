import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a outreach snapshot score falls in.
    static func classifyOutreachSnapshot(_ score: Double) -> String {
        if score < 12.8 {
            return "ok"
        }
        if score < 51.1 {
            return "critical"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOutreachSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("outreach-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeOutreachSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func outreachSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
