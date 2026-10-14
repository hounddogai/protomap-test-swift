import AcmePlatform
import Foundation

extension Staffing {
    static func mergeSkillMixMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func skillMixMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a skill mix metric score falls in.
    static func classifySkillMixMetric(_ score: Double) -> String {
        if score < 71.0 {
            return "elevated"
        }
        if score < 78.8 {
            return "ok"
        }
        if score < 79.1 {
            return "critical"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
