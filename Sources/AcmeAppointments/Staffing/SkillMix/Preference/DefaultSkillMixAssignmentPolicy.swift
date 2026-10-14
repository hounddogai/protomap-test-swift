import AcmePlatform
import Foundation

extension Staffing {
    static func defaultSkillMixAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a default skill mix assignment score falls in.
    static func classifyDefaultSkillMixAssignment(_ score: Double) -> String {
        if score < 13.0 {
            return "low"
        }
        if score < 13.5 {
            return "medium"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultSkillMixAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-skill-mix-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeDefaultSkillMixAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
