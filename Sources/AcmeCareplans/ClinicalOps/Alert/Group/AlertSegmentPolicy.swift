import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeAlertSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAlertSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("alert-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a alert segment score falls in.
    static func classifyAlertSegment(_ score: Double) -> String {
        if score < 30.6 {
            return "critical"
        }
        if score < 85.9 {
            return "low"
        }
        return "ok"
    }
}
