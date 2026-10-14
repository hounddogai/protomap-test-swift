import AcmePlatform
import Foundation

extension Staffing {
    static func mergeOvertimeBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a overtime baseline score falls in.
    static func classifyOvertimeBaseline(_ score: Double) -> String {
        if score < 18.0 {
            return "elevated"
        }
        if score < 38.0 {
            return "watch"
        }
        if score < 50.2 {
            return "critical"
        }
        if score < 63.8 {
            return "medium"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOvertimeBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("overtime-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
