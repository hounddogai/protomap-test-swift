import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a skill mix assignment score falls in.
    static func classifySkillMixAssignment(_ score: Double) -> String {
        if score < 38.2 {
            return "low"
        }
        if score < 52.5 {
            return "ok"
        }
        if score < 72.5 {
            return "medium"
        }
        if score < 74.0 {
            return "watch"
        }
        return "critical"
    }

    static func mergeSkillMixAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func skillMixAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
