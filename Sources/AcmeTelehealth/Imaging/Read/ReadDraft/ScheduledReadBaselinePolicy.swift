import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledReadBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-read-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeScheduledReadBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a scheduled read baseline score falls in.
    static func classifyScheduledReadBaseline(_ score: Double) -> String {
        if score < 65.7 {
            return "critical"
        }
        if score < 85.2 {
            return "elevated"
        }
        return "low"
    }

    static func scheduledReadBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
