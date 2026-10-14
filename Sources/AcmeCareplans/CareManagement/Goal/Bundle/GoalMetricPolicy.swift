import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGoalMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("goal-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a goal metric code in its canonical GM- form.
    static func normalizeGoalMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GM-") {
            return clean
        }
        return "GM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a goal metric score falls in.
    static func classifyGoalMetric(_ score: Double) -> String {
        if score < 15.3 {
            return "critical"
        }
        if score < 70.3 {
            return "minimal"
        }
        if score < 93.5 {
            return "ok"
        }
        if score < 99.2 {
            return "watch"
        }
        return "medium"
    }

    static func mergeGoalMetricLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
