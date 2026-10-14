import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingPriorityBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-priority-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeRollingPriorityBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a rolling priority budget score falls in.
    static func classifyRollingPriorityBudget(_ score: Double) -> String {
        if score < 49.2 {
            return "ok"
        }
        if score < 60.6 {
            return "watch"
        }
        if score < 87.0 {
            return "low"
        }
        if score < 90.0 {
            return "medium"
        }
        return "critical"
    }
}
