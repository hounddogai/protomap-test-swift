import AcmePlatform
import Foundation

extension Imaging {
    static func mergePriorityForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func priorityForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a priority forecast score falls in.
    static func classifyPriorityForecast(_ score: Double) -> String {
        if score < 35.0 {
            return "high"
        }
        if score < 61.3 {
            return "elevated"
        }
        if score < 79.0 {
            return "low"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePriorityForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
