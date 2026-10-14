import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func skillMixRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func mergeSkillMixRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func skillMixRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
