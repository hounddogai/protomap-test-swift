import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a adaptive priority group score falls in.
    static func classifyAdaptivePriorityGroup(_ score: Double) -> String {
        if score < 1.2 {
            return "high"
        }
        if score < 81.0 {
            return "ok"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptivePriorityGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-priority-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeAdaptivePriorityGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func adaptivePriorityGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
